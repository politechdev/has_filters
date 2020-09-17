require "has_filters/version"
require "active_support/concern"

require_relative "has_filters/operators"

# Provides an API for easily defining scopes on models for strings, integers, and dates,
# each with its own rule options for matching (e.g. exact, partial, range). includes
# support for joins.
#
# Usage:
#   class SomeModel
#     include HasFilters
#     has_filters :first_name, :joined_model, scopes: %i(custom_scope),
#                                             aliases: {
#                                               full_name: "first_name || last_name"
#                                             }
#   end
#
#  SomeModel.by_name("Hello")
#  SomeModel.by_full_name("Hello World")
#  SomeModel.by_joined_model_name(containing: "ello")
#  SomeModel.filter([column: "custom_scope", param: ["argument"]])
module HasFilters
  class UnfilterableJoinError < StandardError; end
  class InvalidFilterError < StandardError; end
  class UnfilterableAttrError < StandardError; end

  extend ActiveSupport::Concern

  included do
    class << self
      attr_reader :filterable_attrs
      attr_reader :allowed_scopes
    end
  end

  module ClassMethods
    def filter(rules: [], conjunction: :exclusive)
      raise InvalidFilterError, "Invalid rules object" unless rules.is_a?(Array) && rules.all? { |r| r.respond_to?(:to_h) }

      return all unless rules.any?

      filter_scope = compose_filters(rules, conjunction.to_sym)

      all.merge(filter_scope)
    end

    def has_filters(*configs)
      @filterable_attrs = []
      @allowed_scopes = []
      @filtered_assocs = []

      configs.reject { |c| c.is_a?(Hash) || reflect_on_all_associations.detect { |a| a.name == c.to_sym } }.each do |column|
        define_column_filter(column)
      end

      configs.select { |c| c.is_a?(Hash) }.each do |config|
        define_virtual_filters(config[:aliases]) if config[:aliases].present?

        @allowed_scopes += config[:scopes].to_a
      end

      configs.reject { |c| c.is_a?(Hash) }.map { |c| reflect_on_all_associations.detect { |a| a.name == c.to_sym } }.compact.each do |assoc|
        @filtered_assocs << assoc

        define_association_filters(assoc)
      end
    end

    private

    def compose_filters(rules, conjunction)
      rules = rules.map { |r| r.to_h.symbolize_keys }

      base_rule = rules.pop

      nested = base_rule.key?(:rules)

      base_filter = if nested
                      filter(base_rule)
                    else
                      (filter_method, filter_args) = extract_filter_args(base_rule)

                      try_apply_filter(unscoped, filter_method, filter_args)
                    end

      rules.inject(base_filter) do |existing_scope, rule|
        nested = rule.key?(:rules)

        (filter_method, filter_args) = nested ? [:filter, [rule]] : extract_filter_args(rule)

        if conjunction == :exclusive
          try_apply_filter(existing_scope, filter_method, filter_args)
        else
          filtered_scope = try_apply_filter(unscoped, filter_method, filter_args)

          all.except(:limit, :offset)
             .where(id: existing_scope)
             .or(
               all.except(:limit, :offset)
                  .where(id: filtered_scope)
             )
        end
      end
    end

    def extract_filter_args(rule)
      return :all if rule.blank?

      rule = rule.to_h.symbolize_keys

      if @allowed_scopes.include?(rule[:column].try(:to_sym))
        scope = rule[:column]
        params = rule[:param]
        params = params.symbolize_keys if params.is_a?(Hash)

        return [scope, Array.wrap(params)]
      end

      raise InvalidFilterError, "Invalid rule object: #{rule.inspect}" unless %i(column operator param).all? { |k| rule.key?(k) }

      [
        :"by_#{rule[:column]}",
        [
          {
            rule[:operator].to_sym => rule[:param],
            :invert => ActiveRecord::Type::Boolean.new.deserialize(rule[:invert])
          }
        ]
      ]
    end

    def define_virtual_filters(filters)
      filters.each do |scope_name, definition|
        @filterable_attrs << scope_name.to_sym

        define_singleton_method :"by_#{scope_name}" do |rule|
          Operators.derive_query(all, definition, rule)
        end
      end
    end

    def define_association_filters(assoc)
      raise UnfilterableJoinError, "#{name} is not filterable by #{assoc.klass.name}" unless assoc.klass.respond_to?(:filterable_attrs)

      ([:id] + assoc.klass.filterable_attrs.to_a).each do |assoc_attr|
        define_singleton_method association_filter_name(assoc, assoc_attr) do |rule|
          inverted = rule.is_a?(Hash) && rule.delete(:invert)

          query = includes(assoc.name).merge(association_query(assoc, assoc_attr, rule))
                                      .references(assoc.name)

          query = where.not(id: query) if inverted

          query
        end
      end

      assoc.klass.allowed_scopes.to_a.each do |assoc_scope_name|
        scope_name = "#{assoc.name}_#{assoc_scope_name}".to_sym

        define_singleton_method scope_name do |*args|
          includes(assoc.name).merge(assoc.klass.send(assoc_scope_name, *args))
                              .references(assoc.name)
        end
      end
    end

    def association_query(assoc, attr, rule)
      if attr == :id
        Operators.derive_query(assoc.klass, attr, rule)
      else
        assoc.klass.send(:"by_#{attr}", rule)
      end
    end

    def association_filter_name(assoc, attr)
      "by_#{assoc.name}".tap do |name|
        name << (attr == :id ? "" : "_#{attr}")
      end.to_sym
    end

    def define_column_filter(attr)
      @filterable_attrs << attr

      define_singleton_method :"by_#{attr}" do |rule|
        Operators.derive_query(all, attr, rule)
      end
    end

    def try_apply_filter(scope, filter_name, filter_args)
      scope.send(filter_name, *filter_args)
    rescue NoMethodError
      raise UnfilterableAttrError, "could not compose filter named #{filter_name}"
    end
  end
end

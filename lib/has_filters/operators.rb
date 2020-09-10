require_relative "operators/containment"
require_relative "operators/exact"
require_relative "operators/greater"
require_relative "operators/lesser"
require_relative "operators/range"

module HasFilters
  module Operators
    class InvalidFilterParam < StandardError; end

    BY_NAME = {
      is: HasFilters::Operators::Exact,
      containing: HasFilters::Operators::Containment,
      within: HasFilters::Operators::Range,
      between: HasFilters::Operators::Range,
      more_than: HasFilters::Operators::Greater,
      after: HasFilters::Operators::Greater,
      less_than: HasFilters::Operators::Lesser,
      before: HasFilters::Operators::Lesser
    }.freeze

    def self.derive_query(scope, attr, rule)
      operator_name, param, inverted = if rule.is_a?(Hash)
                                         [rule.keys.first, rule.values.first, rule[:invert] || false]
                                       else
                                         [:is, rule, false]
                                       end

      operator_klass = BY_NAME[operator_name]

      raise ArgumentError, "No rule identified by #{operator_name}" unless operator_klass

      query = operator_klass.new(scope, attr, param)
                            .query

      query = scope.where.not(id: query) if inverted

      query
    end
  end
end

module HasFilters
  module Operators
    class Base
      ALLOWED_TYPES = %i(string integer date datetime float boolean text).freeze

      attr_accessor :scope, :attr, :value, :column

      def initialize(initial_scope, attr, value)
        self.scope = initial_scope
        self.attr = attr
        self.value = value
        self.column = scope.columns.detect { |c| c.name == attr.to_s }

        raise ArgumentError, "Cannot apply #{self.class.name} rule to #{column.type}" unless virtual? || self.class::ALLOWED_TYPES.include?(column.type)
      end

      private

      def virtual?
        attr.is_a?(String)
      end

      def sql_column_name
        if !virtual?
          "#{scope.table_name}.#{attr}"
        else
          attr
        end
      end
    end
  end
end

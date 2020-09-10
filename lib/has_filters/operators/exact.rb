require_relative "base"

module HasFilters
  module Operators
    class Exact < Base
      def query
        if virtual?
          scope.where("#{sql_column_name} #{value.nil? ? 'IS NULL' : '= ?'}", type_cast_value)
        else
          scope.where(attr => value)
        end
      end

      private

      def type_cast_value
        value.is_a?(String) ? scope.connection.type_cast(value, column) : value
      end
    end
  end
end

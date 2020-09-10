module HasFilters
  module Operators
    class Range < Base
      ALLOWED_TYPES = %i(datetime date integer float).freeze

      def query
        scope.where("#{sql_column_name} >= ?", value_to_array.first)
             .where("#{sql_column_name} <= ?", value_to_array.last)
      end

      private

      def value_to_array
        value.minmax
      rescue NoMethodError
        raise InvalidFilterParam, "Range filter param must be an object that responds to #minmax"
      end
    end
  end
end

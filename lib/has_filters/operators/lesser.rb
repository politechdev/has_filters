module HasFilters
  module Operators
    class Lesser < Base
      ALLOWED_TYPES = %i(datetime date integer float).freeze

      def query
        scope.where("#{sql_column_name} <= ?", value)
      end
    end
  end
end

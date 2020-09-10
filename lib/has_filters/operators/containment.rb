require_relative "base"

module HasFilters
  module Operators
    class Containment < Base
      ALLOWED_TYPES = %i(string text).freeze

      def query
        scope.where("position(lower(?) IN lower(#{sql_column_name})) > 0", value)
      end
    end
  end
end

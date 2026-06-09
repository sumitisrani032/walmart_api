# frozen_string_literal: true

module WalmartApi
  module Resources
    class Base
      def initialize(connection)
        @connection = connection
      end

      private

      def get(path, params = {})
        @connection.get(path, params)
      end

      def post(path, body = nil)
        @connection.post(path, body)
      end

      def put(path, body = nil)
        @connection.put(path, body)
      end

      def delete(path, params = {})
        @connection.delete(path, params)
      end
    end
  end
end

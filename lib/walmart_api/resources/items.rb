# frozen_string_literal: true

module WalmartApi
  module Resources
    class Items < Base
      PARAM_MAP = {
        lifecycle_status: "lifecycleStatus",
        published_status: "publishedStatus",
        limit: "limit",
        next_cursor: "nextCursor"
      }.freeze

      def list(**filters)
        params = build_params(filters)
        response = get("/v3/items", params)
        body = response.body

        elements = body["items"] || []
        next_cursor = body["nextCursor"]

        PaginatedResponse.new(body, items: elements, next_cursor: next_cursor)
      end

      def find(sku)
        response = get("/v3/items/#{sku}")
        Response.new(response.body)
      end

      private

      def build_params(filters)
        filters.each_with_object({}) do |(key, value), params|
          walmart_key = PARAM_MAP.fetch(key) { raise ArgumentError, "Unknown filter: #{key}" }
          params[walmart_key] = value
        end
      end
    end
  end
end

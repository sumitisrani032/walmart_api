# frozen_string_literal: true

module WalmartApi
  module Resources
    class Orders < Base
      PARAM_MAP = {
        status: "status",
        created_start_date: "createdStartDate",
        created_end_date: "createdEndDate",
        limit: "limit",
        next_cursor: "nextCursor",
        ship_node_type: "shipNodeType"
      }.freeze

      def list(**filters)
        params = build_params(filters)
        response = get("/v3/orders", params)
        body = response.body

        elements = body.dig("list", "elements", "order") || []
        next_cursor = body.dig("list", "meta", "nextCursor")

        PaginatedResponse.new(body, items: elements, next_cursor: next_cursor)
      end

      def find(purchase_order_id)
        response = get("/v3/orders/#{purchase_order_id}")
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

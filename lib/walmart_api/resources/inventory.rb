# frozen_string_literal: true

module WalmartApi
  module Resources
    class Inventory < Base
      GET_PARAM_MAP = {
        sku: "sku",
        ship_node: "shipNode"
      }.freeze

      UPDATE_FIELD_MAP = {
        quantity: "quantity",
        ship_node: "shipNode",
        inventory_available_date: "inventoryAvailableDate"
      }.freeze

      def get(sku, ship_node: nil)
        params = build_get_params(sku, ship_node)
        response = super("/v3/inventory", params)
        Response.new(response.body)
      end

      def update(sku, quantity: nil, ship_node: nil, inventory_available_date: nil)
        body = build_update_body(sku, quantity, ship_node, inventory_available_date)
        response = put("/v3/inventory", body)
        Response.new(response.body)
      end

      private

      def build_get_params(sku, ship_node)
        params = { sku: sku }
        params[:shipNode] = ship_node unless ship_node.nil?
        params
      end

      def build_update_body(sku, quantity, ship_node, inventory_available_date)
        body = {
          sku: sku,
          quantity: {
            unit: "EACH",
            amount: quantity
          }
        }

        body[:shipNode] = ship_node unless ship_node.nil?
        body[:inventoryAvailableDate] = inventory_available_date unless inventory_available_date.nil?

        body
      end
    end
  end
end

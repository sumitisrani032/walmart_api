# frozen_string_literal: true

require "json"

RSpec.describe WalmartApi::Resources::Inventory do
  let(:connection) { instance_double(Faraday::Connection) }
  let(:inventory) { described_class.new(connection) }
  let(:inventory_body) { JSON.parse(File.read("spec/fixtures/inventory/inventory.json")) }
  let(:get_response) { instance_double(Faraday::Response, body: inventory_body) }
  let(:update_response) { instance_double(Faraday::Response, body: inventory_body) }

  describe "#get" do
    before { allow(connection).to receive(:get).and_return(get_response) }

    it "sends GET to /v3/inventory" do
      inventory.get("SKU-001")

      expect(connection).to have_received(:get).with("/v3/inventory", { sku: "SKU-001" })
    end

    it "passes sku parameter" do
      inventory.get("SKU-123")

      expect(connection).to have_received(:get).with("/v3/inventory", { sku: "SKU-123" })
    end

    it "passes ship_node as shipNode" do
      inventory.get("SKU-001", ship_node: "node_456")

      expect(connection).to have_received(:get).with(
        "/v3/inventory",
        { sku: "SKU-001", shipNode: "node_456" }
      )
    end

    it "returns a Response" do
      expect(inventory.get("SKU-001")).to be_a(WalmartApi::Response)
    end

    it "exposes sku from response" do
      response = inventory.get("SKU-001")

      expect(response.sku).to eq("SKU-001")
    end

    it "exposes quantity from response" do
      response = inventory.get("SKU-001")

      expect(response.quantity).to be_a(WalmartApi::Response)
    end

    it "exposes quantity unit" do
      response = inventory.get("SKU-001")

      expect(response.quantity.unit).to eq("EACH")
    end

    it "exposes quantity amount" do
      response = inventory.get("SKU-001")

      expect(response.quantity.amount).to eq(150)
    end

    it "raises NotFoundError for 404 via error middleware" do
      conn = Faraday.new do |f|
        f.use WalmartApi::Middleware::ErrorHandler
        f.adapter :test do |stub|
          stub.get("/v3/inventory") { [404, {}, '{"errors":[{"description":"SKU not found"}]}'] }
        end
      end

      expect { described_class.new(conn).get("NONEXISTENT") }.to raise_error(WalmartApi::NotFoundError)
    end
  end

  describe "#update" do
    before { allow(connection).to receive(:put).and_return(update_response) }

    it "sends PUT to /v3/inventory" do
      inventory.update("SKU-001", quantity: 150)

      expect(connection).to have_received(:put).with(
        "/v3/inventory",
        {
          sku: "SKU-001",
          quantity: {
            unit: "EACH",
            amount: 150
          }
        }
      )
    end

    it "passes quantity in correct structure" do
      inventory.update("SKU-001", quantity: 75)

      expect(connection).to have_received(:put).with(
        "/v3/inventory",
        {
          sku: "SKU-001",
          quantity: {
            unit: "EACH",
            amount: 75
          }
        }
      )
    end

    it "passes ship_node as shipNode" do
      inventory.update("SKU-001", quantity: 150, ship_node: "node_789")

      expect(connection).to have_received(:put).with(
        "/v3/inventory",
        {
          sku: "SKU-001",
          quantity: {
            unit: "EACH",
            amount: 150
          },
          shipNode: "node_789"
        }
      )
    end

    it "passes inventory_available_date as inventoryAvailableDate" do
      inventory.update(
        "SKU-001",
        quantity: 150,
        inventory_available_date: "2025-07-15T00:00:00.000Z"
      )

      expect(connection).to have_received(:put).with(
        "/v3/inventory",
        {
          sku: "SKU-001",
          quantity: {
            unit: "EACH",
            amount: 150
          },
          inventoryAvailableDate: "2025-07-15T00:00:00.000Z"
        }
      )
    end

    it "passes all optional parameters when provided" do
      inventory.update(
        "SKU-001",
        quantity: 150,
        ship_node: "node_123",
        inventory_available_date: "2025-07-15T00:00:00.000Z"
      )

      expect(connection).to have_received(:put).with(
        "/v3/inventory",
        {
          sku: "SKU-001",
          quantity: {
            unit: "EACH",
            amount: 150
          },
          shipNode: "node_123",
          inventoryAvailableDate: "2025-07-15T00:00:00.000Z"
        }
      )
    end

    it "returns a Response" do
      expect(inventory.update("SKU-001", quantity: 150)).to be_a(WalmartApi::Response)
    end

    it "raises ValidationError for 400 via error middleware" do
      conn = Faraday.new do |f|
        f.use WalmartApi::Middleware::ErrorHandler
        f.adapter :test do |stub|
          stub.put("/v3/inventory") { [400, {}, '{"errors":[{"description":"Invalid quantity"}]}'] }
        end
      end

      expect { described_class.new(conn).update("SKU-001", quantity: -5) }.to raise_error(WalmartApi::ValidationError)
    end

    it "raises NotFoundError for 404 via error middleware" do
      conn = Faraday.new do |f|
        f.use WalmartApi::Middleware::ErrorHandler
        f.adapter :test do |stub|
          stub.put("/v3/inventory") { [404, {}, '{"errors":[{"description":"SKU not found"}]}'] }
        end
      end

      expect { described_class.new(conn).update("NONEXISTENT", quantity: 150) }.to raise_error(WalmartApi::NotFoundError)
    end
  end
end

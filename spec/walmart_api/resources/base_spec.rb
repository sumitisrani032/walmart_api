# frozen_string_literal: true

RSpec.describe WalmartApi::Resources::Base do
  let(:connection) { instance_double(Faraday::Connection) }
  let(:resource) { described_class.new(connection) }
  let(:response) { instance_double(Faraday::Response, body: { "sku" => "ABC-123" }) }

  describe "#get" do
    before { allow(connection).to receive(:get).and_return(response) }

    it "delegates to the Faraday connection" do
      expect(resource.send(:get, "/v3/orders", {})).to eq(response)
    end

    it "passes path correctly" do
      resource.send(:get, "/v3/orders", {})

      expect(connection).to have_received(:get).with("/v3/orders", {})
    end

    it "passes params correctly" do
      resource.send(:get, "/v3/orders", status: "Created", limit: 20)

      expect(connection).to have_received(:get).with("/v3/orders", status: "Created", limit: 20)
    end
  end

  describe "#post" do
    before { allow(connection).to receive(:post).and_return(response) }

    it "delegates to the Faraday connection" do
      expect(resource.send(:post, "/v3/orders", { sku: "ABC" })).to eq(response)
    end

    it "passes path correctly" do
      resource.send(:post, "/v3/orders", { sku: "ABC" })

      expect(connection).to have_received(:post).with("/v3/orders", { sku: "ABC" })
    end

    it "passes body correctly" do
      body = { "inventories" => [{ "sku" => "ABC", "quantity" => { "amount" => 10 } }] }
      resource.send(:post, "/v3/inventory", body)

      expect(connection).to have_received(:post).with("/v3/inventory", body)
    end
  end

  describe "#put" do
    before { allow(connection).to receive(:put).and_return(response) }

    it "delegates to the Faraday connection" do
      expect(resource.send(:put, "/v3/inventory", { quantity: 150 })).to eq(response)
    end

    it "passes path correctly" do
      resource.send(:put, "/v3/inventory", { quantity: 150 })

      expect(connection).to have_received(:put).with("/v3/inventory", { quantity: 150 })
    end

    it "passes body correctly" do
      body = { "sku" => "ABC-123", "quantity" => { "unit" => "EACH", "amount" => 50 } }
      resource.send(:put, "/v3/inventory", body)

      expect(connection).to have_received(:put).with("/v3/inventory", body)
    end
  end

  describe "#delete" do
    before { allow(connection).to receive(:delete).and_return(response) }

    it "delegates to the Faraday connection" do
      expect(resource.send(:delete, "/v3/items/ABC-123", {})).to eq(response)
    end

    it "passes path correctly" do
      resource.send(:delete, "/v3/items/ABC-123", {})

      expect(connection).to have_received(:delete).with("/v3/items/ABC-123", {})
    end

    it "passes params correctly" do
      resource.send(:delete, "/v3/items/ABC-123", force: true)

      expect(connection).to have_received(:delete).with("/v3/items/ABC-123", force: true)
    end
  end
end

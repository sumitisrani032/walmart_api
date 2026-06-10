# frozen_string_literal: true

require "json"

RSpec.describe WalmartApi::Resources::Items do
  let(:connection) { instance_double(Faraday::Connection) }
  let(:items) { described_class.new(connection) }
  let(:item_list_body) { JSON.parse(File.read("spec/fixtures/items/item_list.json")) }
  let(:single_item_body) { JSON.parse(File.read("spec/fixtures/items/single_item.json")) }
  let(:list_response) { instance_double(Faraday::Response, body: item_list_body) }
  let(:find_response) { instance_double(Faraday::Response, body: single_item_body) }

  describe "#list" do
    before { allow(connection).to receive(:get).and_return(list_response) }

    it "sends GET to /v3/items" do
      items.list

      expect(connection).to have_received(:get).with("/v3/items", {})
    end

    it "passes lifecycle_status as lifecycleStatus" do
      items.list(lifecycle_status: "ACTIVE")

      expect(connection).to have_received(:get).with("/v3/items", "lifecycleStatus" => "ACTIVE")
    end

    it "passes published_status as publishedStatus" do
      items.list(published_status: "PUBLISHED")

      expect(connection).to have_received(:get).with("/v3/items", "publishedStatus" => "PUBLISHED")
    end

    it "passes limit" do
      items.list(limit: 50)

      expect(connection).to have_received(:get).with("/v3/items", "limit" => 50)
    end

    it "passes next_cursor as nextCursor" do
      items.list(next_cursor: "abc123")

      expect(connection).to have_received(:get).with("/v3/items", "nextCursor" => "abc123")
    end

    it "passes multiple filters" do
      items.list(lifecycle_status: "ACTIVE", published_status: "PUBLISHED", limit: 20)

      expect(connection).to have_received(:get).with(
        "/v3/items",
        "lifecycleStatus" => "ACTIVE", "publishedStatus" => "PUBLISHED", "limit" => 20
      )
    end

    it "returns a PaginatedResponse" do
      expect(items.list).to be_a(WalmartApi::PaginatedResponse)
    end

    it "exposes next_cursor from response" do
      expect(items.list.next_cursor).to eq("cursor_next_page_123")
    end

    it "exposes item items" do
      result = items.list

      expect(result.items.length).to eq(2)
    end

    it "wraps item items as Response objects" do
      result = items.list

      expect(result.items.first).to be_a(WalmartApi::Response)
    end

    it "provides method access on item items" do
      result = items.list

      expect(result.items.first.sku).to eq("SKU-001")
    end

    it "raises ArgumentError for unknown filters" do
      expect { items.list(invalid_param: "value") }.to raise_error(ArgumentError, /Unknown filter: invalid_param/)
    end
  end

  describe "#find" do
    before { allow(connection).to receive(:get).and_return(find_response) }

    it "sends GET to /v3/items/{sku}" do
      items.find("SKU-001")

      expect(connection).to have_received(:get).with("/v3/items/SKU-001", {})
    end

    it "returns a Response" do
      expect(items.find("SKU-001")).to be_a(WalmartApi::Response)
    end
  end

  describe "response wrapper integration" do
    before { allow(connection).to receive(:get).and_return(find_response) }

    let(:item) { items.find("SKU-001") }

    it "exposes sku" do
      expect(item.sku).to eq("SKU-001")
    end

    it "exposes product_name" do
      expect(item.product_name).to eq("Awesome Widget")
    end

    it "exposes product_type" do
      expect(item.product_type).to eq("Electronics")
    end

    it "exposes published_status" do
      expect(item.published_status).to eq("PUBLISHED")
    end

    it "exposes lifecycle_status" do
      expect(item.lifecycle_status).to eq("ACTIVE")
    end

    describe "nested price" do
      it "exposes price" do
        expect(item.price).to be_a(WalmartApi::Response)
      end

      it "exposes price amount" do
        expect(item.price.amount).to eq(99.99)
      end

      it "exposes price currency" do
        expect(item.price.currency).to eq("USD")
      end
    end
  end

  describe "error handling" do
    it "raises NotFoundError for 404 via error middleware" do
      conn = Faraday.new do |f|
        f.use WalmartApi::Middleware::ErrorHandler
        f.adapter :test do |stub|
          stub.get("/v3/items/nonexistent") { [404, {}, '{"errors":[{"description":"Not found"}]}'] }
        end
      end

      expect { described_class.new(conn).find("nonexistent") }.to raise_error(WalmartApi::NotFoundError)
    end
  end
end

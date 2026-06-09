# frozen_string_literal: true

require "json"

RSpec.describe WalmartApi::Resources::Orders do
  let(:connection) { instance_double(Faraday::Connection) }
  let(:orders) { described_class.new(connection) }
  let(:order_list_body) { JSON.parse(File.read("spec/fixtures/orders/order_list.json")) }
  let(:single_order_body) { JSON.parse(File.read("spec/fixtures/orders/single_order.json")) }
  let(:list_response) { instance_double(Faraday::Response, body: order_list_body) }
  let(:find_response) { instance_double(Faraday::Response, body: single_order_body) }

  describe "#list" do
    before { allow(connection).to receive(:get).and_return(list_response) }

    it "sends GET to /v3/orders" do
      orders.list

      expect(connection).to have_received(:get).with("/v3/orders", {})
    end

    it "passes status filter" do
      orders.list(status: "Created")

      expect(connection).to have_received(:get).with("/v3/orders", "status" => "Created")
    end

    it "passes created_start_date as createdStartDate" do
      orders.list(created_start_date: "2025-01-01T00:00:00.000Z")

      expect(connection).to have_received(:get)
        .with("/v3/orders", "createdStartDate" => "2025-01-01T00:00:00.000Z")
    end

    it "passes created_end_date as createdEndDate" do
      orders.list(created_end_date: "2025-06-07T23:59:59.000Z")

      expect(connection).to have_received(:get)
        .with("/v3/orders", "createdEndDate" => "2025-06-07T23:59:59.000Z")
    end

    it "passes limit" do
      orders.list(limit: 50)

      expect(connection).to have_received(:get).with("/v3/orders", "limit" => 50)
    end

    it "passes next_cursor as nextCursor" do
      orders.list(next_cursor: "abc123")

      expect(connection).to have_received(:get).with("/v3/orders", "nextCursor" => "abc123")
    end

    it "passes ship_node_type as shipNodeType" do
      orders.list(ship_node_type: "SellerFulfilled")

      expect(connection).to have_received(:get).with("/v3/orders", "shipNodeType" => "SellerFulfilled")
    end

    it "passes multiple filters" do
      orders.list(status: "Created", limit: 20, ship_node_type: "SellerFulfilled")

      expect(connection).to have_received(:get).with(
        "/v3/orders",
        "status" => "Created", "limit" => 20, "shipNodeType" => "SellerFulfilled"
      )
    end

    it "returns a PaginatedResponse" do
      expect(orders.list).to be_a(WalmartApi::PaginatedResponse)
    end

    it "exposes next_cursor from response" do
      expect(orders.list.next_cursor).to eq("cursor_next_page_123")
    end

    it "exposes order items" do
      result = orders.list

      expect(result.items.length).to eq(2)
    end

    it "wraps order items as Response objects" do
      result = orders.list

      expect(result.items.first).to be_a(WalmartApi::Response)
    end

    it "provides method access on order items" do
      result = orders.list

      expect(result.items.first.purchase_order_id).to eq("2577374099943")
    end

    it "raises ArgumentError for unknown filters" do
      expect { orders.list(invalid_param: "value") }.to raise_error(ArgumentError, /Unknown filter: invalid_param/)
    end
  end

  describe "#find" do
    before { allow(connection).to receive(:get).and_return(find_response) }

    it "sends GET to /v3/orders/{purchaseOrderId}" do
      orders.find("2577374099943")

      expect(connection).to have_received(:get).with("/v3/orders/2577374099943", {})
    end

    it "returns a Response" do
      expect(orders.find("2577374099943")).to be_a(WalmartApi::Response)
    end
  end

  describe "response wrapper integration" do
    before { allow(connection).to receive(:get).and_return(find_response) }

    let(:order) { orders.find("2577374099943") }

    it "exposes purchase_order_id" do
      expect(order.purchase_order_id).to eq("2577374099943")
    end

    it "exposes customer_order_id" do
      expect(order.customer_order_id).to eq("4021838399813")
    end

    it "exposes order_date" do
      expect(order.order_date).to eq(1_622_548_800_000)
    end

    describe "nested order lines" do
      let(:order_line) { order.order_lines.order_line.first }

      it "exposes line_number" do
        expect(order_line.line_number).to eq("1")
      end

      it "exposes item" do
        expect(order_line.item).to be_a(WalmartApi::Response)
      end

      it "exposes item product_name" do
        expect(order_line.item.product_name).to eq("Awesome Widget")
      end

      it "exposes item sku" do
        expect(order_line.item.sku).to eq("SKU-001")
      end

      it "exposes charges" do
        expect(order_line.charges).to be_a(WalmartApi::Response)
      end

      it "exposes charge details" do
        charge = order_line.charges.charge.first

        expect(charge.charge_type).to eq("PRODUCT")
      end

      it "exposes quantity" do
        expect(order_line.order_line_quantity.unit_of_measurement).to eq("EACH")
      end

      it "exposes quantity amount" do
        expect(order_line.order_line_quantity.amount).to eq("1")
      end

      it "exposes order line statuses" do
        status = order_line.order_line_statuses.order_line_status.first

        expect(status.status).to eq("Created")
      end
    end
  end

  describe "error handling" do
    it "raises NotFoundError for 404 via error middleware" do
      conn = Faraday.new do |f|
        f.use WalmartApi::Middleware::ErrorHandler
        f.adapter :test do |stub|
          stub.get("/v3/orders/nonexistent") { [404, {}, '{"errors":[{"description":"Not found"}]}'] }
        end
      end

      expect { described_class.new(conn).find("nonexistent") }.to raise_error(WalmartApi::NotFoundError)
    end
  end
end

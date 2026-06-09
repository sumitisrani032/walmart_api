# frozen_string_literal: true

RSpec.describe WalmartApi::PaginatedResponse do
  let(:items_data) do
    [
      { "sku" => "ABC-123", "productName" => "Widget A" },
      { "sku" => "XYZ-789", "productName" => "Widget B" }
    ]
  end

  let(:response_data) { { "totalCount" => 100, "limit" => 20 } }

  describe "#next_cursor" do
    it "exposes next_cursor when present" do
      response = described_class.new(response_data, items: items_data, next_cursor: "cursor_abc123")

      expect(response.next_cursor).to eq("cursor_abc123")
    end

    it "returns nil when cursor is absent" do
      expect(described_class.new(response_data, items: items_data).next_cursor).to be_nil
    end

    it "returns nil when cursor is explicitly nil" do
      expect(described_class.new(response_data, items: items_data, next_cursor: nil).next_cursor).to be_nil
    end
  end

  describe "#items" do
    it "wraps items as Response objects" do
      expect(described_class.new(response_data, items: items_data).items).to all(be_a(WalmartApi::Response))
    end

    it "provides method access on wrapped items" do
      expect(described_class.new(response_data, items: items_data).items.first.sku).to eq("ABC-123")
    end

    it "converts camelCase keys on wrapped items" do
      expect(described_class.new(response_data, items: items_data).items.first.product_name).to eq("Widget A")
    end
  end

  describe "Enumerable" do
    let(:response) { described_class.new(response_data, items: items_data) }

    it "supports each" do
      skus = response.map(&:sku)

      expect(skus).to eq(%w[ABC-123 XYZ-789])
    end

    it "supports map" do
      expect(response.map(&:sku)).to eq(%w[ABC-123 XYZ-789])
    end

    it "supports select" do
      expect(response.select { |item| item.sku == "ABC-123" }.length).to eq(1)
    end

    it "supports first" do
      expect(response.first.sku).to eq("ABC-123")
    end

    it "supports count" do
      expect(response.count).to eq(2)
    end
  end

  describe "Response inheritance" do
    it "provides method-style access to response metadata" do
      expect(described_class.new(response_data, items: items_data).total_count).to eq(100)
    end

    it "exposes raw hash via to_h" do
      expect(described_class.new(response_data, items: items_data).to_h).to eq(response_data)
    end
  end

  describe "edge cases" do
    it "handles empty items array" do
      expect(described_class.new(response_data, items: []).count).to eq(0)
    end

    it "returns empty array for items when none provided" do
      expect(described_class.new(response_data, items: []).items).to eq([])
    end

    it "handles empty response data" do
      expect(described_class.new({}, items: items_data).to_h).to eq({})
    end

    it "wraps items with nested hashes" do
      nested_items = [{ "sku" => "ABC", "quantity" => { "amount" => 10 } }]

      expect(described_class.new({}, items: nested_items).first.quantity.amount).to eq(10)
    end
  end
end

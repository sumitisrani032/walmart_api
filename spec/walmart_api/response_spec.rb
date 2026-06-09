# frozen_string_literal: true

RSpec.describe WalmartApi::Response do
  describe "top-level key access" do
    it "accesses string keys as methods" do
      expect(described_class.new("sku" => "ABC-123").sku).to eq("ABC-123")
    end

    it "accesses numeric values" do
      expect(described_class.new("quantity" => 10).quantity).to eq(10)
    end
  end

  describe "camelCase to snake_case conversion" do
    it "converts productName to product_name" do
      expect(described_class.new("productName" => "Widget").product_name).to eq("Widget")
    end

    it "converts publishedStatus to published_status" do
      expect(described_class.new("publishedStatus" => "PUBLISHED").published_status).to eq("PUBLISHED")
    end

    it "converts orderLines to order_lines" do
      expect(described_class.new("orderLines" => []).order_lines).to eq([])
    end

    it "converts unitOfMeasurement to unit_of_measurement" do
      expect(described_class.new("unitOfMeasurement" => "EACH").unit_of_measurement).to eq("EACH")
    end

    it "leaves already snake_case keys unchanged" do
      expect(described_class.new("sku" => "ABC").sku).to eq("ABC")
    end
  end

  describe "nested hash wrapping" do
    let(:response) { described_class.new("quantity" => { "amount" => 10, "unit" => "EACH" }) }

    it "wraps nested hashes as Response objects" do
      expect(response.quantity).to be_a(described_class)
    end

    it "provides method access on nested Response" do
      expect(response.quantity.amount).to eq(10)
    end

    it "wraps deeply nested hashes" do
      data = { "order" => { "orderLine" => { "item" => { "productName" => "Widget" } } } }

      expect(described_class.new(data).order.order_line.item.product_name).to eq("Widget")
    end
  end

  describe "array wrapping" do
    let(:data) { { "items" => [{ "sku" => "ABC" }, { "sku" => "XYZ" }] } }
    let(:response) { described_class.new(data) }

    it "returns an Array" do
      expect(response.items).to be_an(Array)
    end

    it "wraps each hash element as a Response" do
      expect(response.items.first).to be_a(described_class)
    end

    it "provides method access on wrapped array elements" do
      expect(response.items.first.sku).to eq("ABC")
    end

    it "preserves arrays of non-hash values" do
      expect(described_class.new("tags" => %w[red blue]).tags).to eq(%w[red blue])
    end

    it "wraps nested arrays of hashes" do
      nested = { "orderLines" => [{ "charges" => [{ "chargeType" => "PRODUCT" }] }] }

      expect(described_class.new(nested).order_lines.first.charges.first.charge_type).to eq("PRODUCT")
    end
  end

  describe "missing keys" do
    it "returns nil for missing keys" do
      expect(described_class.new("sku" => "ABC").nonexistent).to be_nil
    end
  end

  describe "#respond_to_missing?" do
    it "returns true for existing keys" do
      expect(described_class.new("sku" => "ABC")).to respond_to(:sku)
    end

    it "returns true for converted camelCase keys" do
      expect(described_class.new("productName" => "Widget")).to respond_to(:product_name)
    end

    it "returns false for missing keys" do
      expect(described_class.new("sku" => "ABC")).not_to respond_to(:nonexistent)
    end
  end

  describe "#to_h" do
    it "returns the raw hash with original keys" do
      data = { "productName" => "Widget", "publishedStatus" => "PUBLISHED" }

      expect(described_class.new(data).to_h).to eq(data)
    end
  end

  describe "edge cases" do
    it "handles empty hash" do
      expect(described_class.new({}).anything).to be_nil
    end

    it "handles nil values" do
      expect(described_class.new("sku" => nil).sku).to be_nil
    end

    it "handles empty arrays" do
      expect(described_class.new("items" => []).items).to eq([])
    end

    it "handles boolean true" do
      expect(described_class.new("active" => true).active).to be true
    end

    it "handles boolean false" do
      expect(described_class.new("deleted" => false).deleted).to be false
    end

    it "wraps hash elements in mixed arrays" do
      data = { "values" => [{ "id" => 1 }, "plain", 42] }

      expect(described_class.new(data).values.first).to be_a(described_class)
    end

    it "preserves non-hash elements in mixed arrays" do
      data = { "values" => [{ "id" => 1 }, "plain", 42] }

      expect(described_class.new(data).values[1]).to eq("plain")
    end

    it "does not mutate the caller-provided hash" do
      original = { "productName" => "Widget" }
      frozen_copy = original.dup
      described_class.new(original)

      expect(original).to eq(frozen_copy)
    end
  end
end

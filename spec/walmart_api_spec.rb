# frozen_string_literal: true

RSpec.describe WalmartApi do
  it "has a version number" do
    expect(WalmartApi::VERSION).to eq("0.1.0")
  end

  it "loads the WalmartApi module" do
    expect(described_class).to be_a(Module)
  end

  describe ".configure" do
    after { described_class.reset_configuration }

    it "yields the configuration object" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(WalmartApi::Configuration)
    end

    it "sets configuration values via the block" do
      described_class.configure do |config|
        config.client_id = "my_id"
      end

      expect(described_class.configuration.client_id).to eq("my_id")
    end
  end

  describe ".configuration" do
    after { described_class.reset_configuration }

    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(WalmartApi::Configuration)
    end

    it "returns the same instance on repeated calls" do
      first = described_class.configuration
      expect(described_class.configuration).to be(first)
    end
  end

  describe ".reset_configuration" do
    it "replaces the configuration with a new instance" do
      original = described_class.configuration
      described_class.reset_configuration
      expect(described_class.configuration).not_to be(original)
    end

    it "clears previously set values" do
      described_class.configure { |c| c.client_id = "old_id" }
      described_class.reset_configuration
      expect(described_class.configuration.client_id).to be_nil
    end
  end
end

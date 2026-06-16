# frozen_string_literal: true

RSpec.describe WalmartApi::Client do
  let(:client_id) { "test-client-id" }
  let(:client_secret) { "test-client-secret" }
  let(:private_key) { File.read("spec/fixtures/test_private_key.pem") }

  after { WalmartApi.reset_configuration }

  describe "initialization with global configuration" do
    before do
      WalmartApi.configure do |config|
        config.client_id = client_id
        config.client_secret = client_secret
        config.private_key = private_key
      end
    end

    it "initializes using global configuration" do
      client = described_class.new
      expect(client).to be_a(described_class)
    end

    it "builds a Faraday connection" do
      client = described_class.new
      expect(client.instance_variable_get(:@connection)).to be_a(Faraday::Connection)
    end

    it "uses the global configuration base_url" do
      client = described_class.new
      connection = client.instance_variable_get(:@connection)
      expect(connection.url_prefix.to_s).to include("marketplace.walmartapis.com")
    end
  end

  describe "initialization with explicit credentials" do
    it "accepts client_id override" do
      WalmartApi.configure do |config|
        config.client_id = "global-id"
        config.client_secret = client_secret
        config.private_key = private_key
      end

      client = described_class.new(client_id: "override-id")
      config = client.instance_variable_get(:@configuration)
      expect(config.client_id).to eq("override-id")
    end

    it "accepts client_secret override" do
      WalmartApi.configure do |config|
        config.client_id = client_id
        config.client_secret = "global-secret"
        config.private_key = private_key
      end

      client = described_class.new(client_secret: "override-secret")
      config = client.instance_variable_get(:@configuration)
      expect(config.client_secret).to eq("override-secret")
    end

    it "accepts private_key override" do
      override_key = File.read("spec/fixtures/test_private_key.pem")
      WalmartApi.configure do |config|
        config.client_id = client_id
        config.client_secret = client_secret
        config.private_key = private_key
      end

      client = described_class.new(private_key: override_key)
      config = client.instance_variable_get(:@configuration)
      expect(config.private_key).to eq(override_key)
    end

    it "does not mutate global configuration" do
      WalmartApi.configure do |config|
        config.client_id = "global-id"
        config.client_secret = client_secret
        config.private_key = private_key
      end

      original_id = WalmartApi.configuration.client_id
      described_class.new(client_id: "override-id")

      expect(WalmartApi.configuration.client_id).to eq(original_id)
    end
  end

  describe "validation" do
    it "raises ConfigurationError when client_id is missing" do
      WalmartApi.configure do |config|
        config.client_secret = client_secret
        config.private_key = private_key
      end

      expect { described_class.new }.to raise_error(WalmartApi::ConfigurationError)
    end

    it "raises ConfigurationError when client_secret is missing" do
      WalmartApi.configure do |config|
        config.client_id = client_id
        config.private_key = private_key
      end

      expect { described_class.new }.to raise_error(WalmartApi::ConfigurationError)
    end

    it "raises ConfigurationError when private key is missing" do
      WalmartApi.configure do |config|
        config.client_id = client_id
        config.client_secret = client_secret
      end

      expect { described_class.new }.to raise_error(WalmartApi::ConfigurationError)
    end

    it "raises ConfigurationError when no configuration is provided" do
      WalmartApi.reset_configuration

      expect { described_class.new }.to raise_error(WalmartApi::ConfigurationError)
    end
  end

  describe "resource accessors" do
    before do
      WalmartApi.configure do |config|
        config.client_id = client_id
        config.client_secret = client_secret
        config.private_key = private_key
      end
    end

    describe "#orders" do
      it "returns an Orders resource instance" do
        client = described_class.new
        expect(client.orders).to be_a(WalmartApi::Resources::Orders)
      end

      it "passes the connection to the Orders resource" do
        client = described_class.new
        connection = client.instance_variable_get(:@connection)
        expect(client.orders.instance_variable_get(:@connection)).to be(connection)
      end

      it "lazily initializes the resource" do
        client = described_class.new
        first_access = client.orders
        second_access = client.orders
        expect(first_access.object_id).to eq(second_access.object_id)
      end
    end

    describe "#inventory" do
      it "returns an Inventory resource instance" do
        client = described_class.new
        expect(client.inventory).to be_a(WalmartApi::Resources::Inventory)
      end

      it "passes the connection to the Inventory resource" do
        client = described_class.new
        connection = client.instance_variable_get(:@connection)
        expect(client.inventory.instance_variable_get(:@connection)).to be(connection)
      end

      it "lazily initializes the resource" do
        client = described_class.new
        first_access = client.inventory
        second_access = client.inventory
        expect(first_access.object_id).to eq(second_access.object_id)
      end
    end

    describe "#items" do
      it "returns an Items resource instance" do
        client = described_class.new
        expect(client.items).to be_a(WalmartApi::Resources::Items)
      end

      it "passes the connection to the Items resource" do
        client = described_class.new
        connection = client.instance_variable_get(:@connection)
        expect(client.items.instance_variable_get(:@connection)).to be(connection)
      end

      it "lazily initializes the resource" do
        client = described_class.new
        first_access = client.items
        second_access = client.items
        expect(first_access.object_id).to eq(second_access.object_id)
      end
    end
  end

  describe "connection middleware stack" do
    before do
      WalmartApi.configure do |config|
        config.client_id = client_id
        config.client_secret = client_secret
        config.private_key = private_key
      end
    end

    it "includes Authentication middleware" do
      client = described_class.new
      connection = client.instance_variable_get(:@connection)
      middleware_classes = connection.builder.handlers.map { |m| m.is_a?(Faraday::RackBuilder::Handler) ? m.klass : m }
      expect(middleware_classes).to include(WalmartApi::Middleware::Authentication)
    end

    it "includes ErrorHandler middleware" do
      client = described_class.new
      connection = client.instance_variable_get(:@connection)
      middleware_classes = connection.builder.handlers.map { |m| m.is_a?(Faraday::RackBuilder::Handler) ? m.klass : m }
      expect(middleware_classes).to include(WalmartApi::Middleware::ErrorHandler)
    end

    it "includes JSON middleware for request and response" do
      client = described_class.new
      connection = client.instance_variable_get(:@connection)
      middleware_names = connection.builder.handlers.map do |m|
        m.is_a?(Faraday::RackBuilder::Handler) ? m.klass.to_s : m.to_s
      end
      expect(middleware_names.join(",")).to match(/Json/)
    end
  end

  describe "multiple clients" do
    it "supports multiple clients with different credentials" do
      client_a = described_class.new(
        client_id: "id-a",
        client_secret: client_secret,
        private_key: private_key
      )

      config_a = client_a.instance_variable_get(:@configuration)
      expect(config_a.client_id).to eq("id-a")
    end

    it "allows different configs per client" do
      client_b = described_class.new(
        client_id: "id-b",
        client_secret: client_secret,
        private_key: private_key
      )

      config_b = client_b.instance_variable_get(:@configuration)
      expect(config_b.client_id).to eq("id-b")
    end

    it "creates independent connections for each client" do
      client_a = described_class.new(
        client_id: client_id,
        client_secret: client_secret,
        private_key: private_key
      )

      client_b = described_class.new(
        client_id: client_id,
        client_secret: client_secret,
        private_key: private_key
      )

      conn_a = client_a.instance_variable_get(:@connection)
      conn_b = client_b.instance_variable_get(:@connection)

      expect(conn_a.object_id).not_to eq(conn_b.object_id)
    end
  end

  describe "environment configuration" do
    it "uses sandbox environment when specified" do
      client = described_class.new(
        client_id: client_id,
        client_secret: client_secret,
        private_key: private_key,
        environment: :sandbox
      )

      connection = client.instance_variable_get(:@connection)
      expect(connection.url_prefix.to_s).to include("sandbox.walmartapis.com")
    end

    it "uses production environment by default" do
      client = described_class.new(
        client_id: client_id,
        client_secret: client_secret,
        private_key: private_key
      )

      connection = client.instance_variable_get(:@connection)
      expect(connection.url_prefix.to_s).to include("marketplace.walmartapis.com")
    end
  end

  describe "channel type configuration" do
    it "accepts channel_type configuration" do
      client = described_class.new(
        client_id: client_id,
        client_secret: client_secret,
        private_key: private_key,
        channel_type: "my-channel-type"
      )

      config = client.instance_variable_get(:@configuration)
      expect(config.channel_type).to eq("my-channel-type")
    end
  end
end

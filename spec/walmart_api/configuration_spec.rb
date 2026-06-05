# frozen_string_literal: true

RSpec.describe WalmartApi::Configuration do
  subject(:config) { described_class.new }

  describe "accessors" do
    it "sets and reads client_id" do
      config.client_id = "test_id"
      expect(config.client_id).to eq("test_id")
    end

    it "sets and reads client_secret" do
      config.client_secret = "test_secret"
      expect(config.client_secret).to eq("test_secret")
    end

    it "sets and reads private_key" do
      config.private_key = "key_content"
      expect(config.private_key).to eq("key_content")
    end

    it "sets and reads private_key_path" do
      config.private_key_path = "/path/to/key.pem"
      expect(config.private_key_path).to eq("/path/to/key.pem")
    end

    it "sets and reads channel_type" do
      config.channel_type = "SWAGGER_CHANNEL_TYPE"
      expect(config.channel_type).to eq("SWAGGER_CHANNEL_TYPE")
    end
  end

  describe "#environment" do
    it "defaults to :production" do
      expect(config.environment).to eq(:production)
    end

    it "can be set to :sandbox" do
      config.environment = :sandbox
      expect(config.environment).to eq(:sandbox)
    end
  end

  describe "#base_url" do
    it "returns production URL by default" do
      expect(config.base_url).to eq("https://marketplace.walmartapis.com")
    end

    it "returns sandbox URL when environment is :sandbox" do
      config.environment = :sandbox
      expect(config.base_url).to eq("https://sandbox.walmartapis.com")
    end

    it "raises ConfigurationError for unknown environment" do
      config.environment = :staging
      expect { config.base_url }.to raise_error(WalmartApi::ConfigurationError, /unknown environment/)
    end
  end

  describe "#resolved_private_key" do
    let(:fixture_key_path) { File.expand_path("../fixtures/test_private_key.pem", __dir__) }

    it "returns private_key when set" do
      config.private_key = "inline_key_content"
      expect(config.resolved_private_key).to eq("inline_key_content")
    end

    it "prefers private_key over private_key_path when both are set" do
      config.private_key = "inline_key_content"
      config.private_key_path = fixture_key_path
      expect(config.resolved_private_key).to eq("inline_key_content")
    end

    it "reads from private_key_path when private_key is not set" do
      config.private_key_path = fixture_key_path
      expect(config.resolved_private_key).to eq(File.read(fixture_key_path))
    end

    it "returns nil when neither private_key nor private_key_path is set" do
      expect(config.resolved_private_key).to be_nil
    end
  end

  describe "#validate!" do
    let(:fixture_key_path) { File.expand_path("../fixtures/test_private_key.pem", __dir__) }

    before do
      config.client_id = "test_id"
      config.client_secret = "test_secret"
      config.private_key = "test_key"
    end

    it "passes when all required fields are present" do
      expect { config.validate! }.not_to raise_error
    end

    it "raises ConfigurationError when client_id is missing" do
      config.client_id = nil
      expect { config.validate! }.to raise_error(WalmartApi::ConfigurationError, "client_id is required")
    end

    it "raises ConfigurationError when client_secret is missing" do
      config.client_secret = nil
      expect { config.validate! }.to raise_error(WalmartApi::ConfigurationError, "client_secret is required")
    end

    it "raises ConfigurationError when both private_key and private_key_path are missing" do
      config.private_key = nil
      expect { config.validate! }.to raise_error(
        WalmartApi::ConfigurationError, "private_key or private_key_path is required"
      )
    end

    it "raises ConfigurationError when private_key_path points to nonexistent file" do
      config.private_key = nil
      config.private_key_path = "/nonexistent/path/key.pem"
      expect { config.validate! }.to raise_error(
        WalmartApi::ConfigurationError, /private_key_path file not found/
      )
    end

    it "passes when private_key_path points to an existing file" do
      config.private_key = nil
      config.private_key_path = fixture_key_path
      expect { config.validate! }.not_to raise_error
    end
  end
end

# frozen_string_literal: true

RSpec.describe WalmartApi::Middleware::Authentication do
  let(:token_manager) { instance_double(WalmartApi::Auth::TokenManager, access_token: "test_token_xyz") }
  let(:signature_generator) { instance_double(WalmartApi::Auth::SignatureGenerator, sign: "test_signature_base64") }

  let(:configuration) do
    config = WalmartApi::Configuration.new
    config.client_id = "test_consumer_id"
    config.private_key = "test_key"
    config
  end

  let(:captured_headers) { {} }

  let(:connection) do
    Faraday.new(url: "https://marketplace.walmartapis.com") do |f|
      f.use described_class,
            token_manager: token_manager,
            signature_generator: signature_generator,
            configuration: configuration
      f.adapter :test do |stub|
        stub.get("/v3/orders") do |env|
          captured_headers.merge!(env.request_headers)
          [200, {}, "{}"]
        end
      end
    end
  end

  before { connection.get("/v3/orders") }

  describe "required headers" do
    it "adds WM_SEC.ACCESS_TOKEN header" do
      expect(captured_headers["WM_SEC.ACCESS_TOKEN"]).to eq("test_token_xyz")
    end

    it "adds WM_SVC.NAME header" do
      expect(captured_headers["WM_SVC.NAME"]).to eq("Walmart Marketplace")
    end

    it "adds WM_QOS.CORRELATION_ID header" do
      expect(captured_headers["WM_QOS.CORRELATION_ID"]).to be_a(String)
    end

    it "sets correlation ID in UUID format" do
      uuid_pattern = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/
      expect(captured_headers["WM_QOS.CORRELATION_ID"]).to match(uuid_pattern)
    end

    it "adds WM_SEC.TIMESTAMP header" do
      expect(captured_headers["WM_SEC.TIMESTAMP"]).to match(/\A\d{13}\z/)
    end

    it "sets timestamp as Unix epoch milliseconds" do
      ts = captured_headers["WM_SEC.TIMESTAMP"].to_i
      now_ms = (Time.now.to_f * 1000).to_i
      expect(ts).to be_within(5000).of(now_ms)
    end

    it "adds WM_SEC.AUTH_SIGNATURE header" do
      expect(captured_headers["WM_SEC.AUTH_SIGNATURE"]).to eq("test_signature_base64")
    end
  end

  describe "conditional headers" do
    context "when channel_type is configured" do
      before do
        configuration.channel_type = "SWAGGER_CHANNEL_TYPE"
        captured_headers.clear
        connection.get("/v3/orders")
      end

      it "adds WM_CONSUMER.CHANNEL.TYPE header" do
        expect(captured_headers["WM_CONSUMER.CHANNEL.TYPE"]).to eq("SWAGGER_CHANNEL_TYPE")
      end
    end

    context "when channel_type is not configured" do
      it "omits WM_CONSUMER.CHANNEL.TYPE header" do
        expect(captured_headers).not_to have_key("WM_CONSUMER.CHANNEL.TYPE")
      end
    end
  end

  describe "per-request behavior" do
    it "generates a unique correlation ID per request" do
      first_id = captured_headers["WM_QOS.CORRELATION_ID"]
      captured_headers.clear
      connection.get("/v3/orders")
      expect(captured_headers["WM_QOS.CORRELATION_ID"]).not_to eq(first_id)
    end
  end

  describe "dependency integration" do
    it "calls TokenManager to retrieve the access token" do
      expect(token_manager).to have_received(:access_token)
    end

    it "calls SignatureGenerator with consumer_id and timestamp" do
      expect(signature_generator).to have_received(:sign).with(
        consumer_id: "test_consumer_id",
        timestamp: a_string_matching(/\A\d{13}\z/)
      )
    end
  end
end

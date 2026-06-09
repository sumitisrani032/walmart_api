# frozen_string_literal: true

RSpec.describe WalmartApi::Middleware::ErrorHandler do
  let(:correlation_id) { "test-correlation-123" }
  let(:error_body) { { "errors" => [{ "description" => "Something went wrong" }] } }

  let(:connection) do
    Faraday.new do |f|
      f.use described_class
      f.adapter :test do |stub|
        stub.get("/success200") { [200, {}, '{"data":"ok"}'] }
        stub.get("/success201") { [201, {}, '{"data":"created"}'] }
        stub.get("/error400") { [400, headers_with_correlation, error_body.to_json] }
        stub.get("/error401") { [401, headers_with_correlation, error_body.to_json] }
        stub.get("/error403") { [403, headers_with_correlation, error_body.to_json] }
        stub.get("/error404") { [404, headers_with_correlation, error_body.to_json] }
        stub.get("/error429") { [429, headers_with_retry_after, error_body.to_json] }
        stub.get("/error500") { [500, headers_with_correlation, error_body.to_json] }
        stub.get("/error502") { [502, headers_with_correlation, error_body.to_json] }
        stub.get("/error503") { [503, headers_with_correlation, error_body.to_json] }
        stub.get("/error504") { [504, {}, error_body.to_json] }
        stub.get("/invalid_json") { [500, {}, "not json"] }
        stub.get("/empty_body") { [500, {}, ""] }
        stub.get("/plain_text") { [400, {}, "Bad Request"] }
        stub.get("/no_retry_after") { [429, headers_with_correlation, error_body.to_json] }
      end
    end
  end

  def headers_with_correlation
    { "WM_QOS.CORRELATION_ID" => correlation_id }
  end

  def headers_with_retry_after
    { "WM_QOS.CORRELATION_ID" => correlation_id, "Retry-After" => "30" }
  end

  def catch_error(path)
    connection.get(path)
  rescue WalmartApi::ApiError => e
    e
  end

  describe "successful responses" do
    it "passes through 200 responses unchanged" do
      expect(connection.get("/success200").status).to eq(200)
    end

    it "passes through 201 responses unchanged" do
      expect(connection.get("/success201").status).to eq(201)
    end
  end

  describe "error mapping" do
    it "raises ValidationError for 400" do
      expect { connection.get("/error400") }.to raise_error(WalmartApi::ValidationError)
    end

    it "raises AuthenticationError for 401" do
      expect { connection.get("/error401") }.to raise_error(WalmartApi::AuthenticationError)
    end

    it "raises AuthorizationError for 403" do
      expect { connection.get("/error403") }.to raise_error(WalmartApi::AuthorizationError)
    end

    it "raises NotFoundError for 404" do
      expect { connection.get("/error404") }.to raise_error(WalmartApi::NotFoundError)
    end

    it "raises RateLimitError for 429" do
      expect { connection.get("/error429") }.to raise_error(WalmartApi::RateLimitError)
    end

    it "raises ServerError for 500" do
      expect { connection.get("/error500") }.to raise_error(WalmartApi::ServerError)
    end

    it "raises ServerError for 502" do
      expect { connection.get("/error502") }.to raise_error(WalmartApi::ServerError)
    end

    it "raises ServerError for 503" do
      expect { connection.get("/error503") }.to raise_error(WalmartApi::ServerError)
    end

    it "raises ServerError for 504" do
      expect { connection.get("/error504") }.to raise_error(WalmartApi::ServerError)
    end
  end

  describe "correlation ID extraction" do
    it "extracts correlation ID from response header" do
      expect(catch_error("/error400").correlation_id).to eq(correlation_id)
    end

    it "sets correlation ID to nil when header is absent" do
      expect(catch_error("/error504").correlation_id).to be_nil
    end
  end

  describe "Retry-After handling" do
    it "parses Retry-After header into retry_after attribute" do
      expect(catch_error("/error429").retry_after).to eq(30)
    end

    it "sets retry_after to nil when Retry-After header is absent" do
      expect(catch_error("/no_retry_after").retry_after).to be_nil
    end
  end

  describe "body parsing" do
    it "parses JSON response body into exception" do
      expect(catch_error("/error400").body).to eq(error_body)
    end

    it "handles invalid JSON body gracefully" do
      expect(catch_error("/invalid_json").body).to eq({ "raw" => "not json" })
    end

    it "handles plain text body gracefully" do
      expect(catch_error("/plain_text").body).to eq({ "raw" => "Bad Request" })
    end

    it "handles empty body gracefully" do
      expect(catch_error("/empty_body").body).to eq({})
    end
  end

  describe "exception attributes" do
    it "populates status on raised exception" do
      expect(catch_error("/error401").status).to eq(401)
    end

    it "populates body on raised exception" do
      expect(catch_error("/error403").body).to be_a(Hash)
    end

    it "populates correlation_id on raised exception" do
      expect(catch_error("/error500").correlation_id).to eq(correlation_id)
    end
  end
end

# frozen_string_literal: true

# rubocop:disable RSpec/MultipleDescribes
RSpec.describe WalmartApi::Error do
  it "inherits from StandardError" do
    expect(described_class).to be < StandardError
  end
end

RSpec.describe WalmartApi::ConfigurationError do
  it "inherits from WalmartApi::Error" do
    expect(described_class).to be < WalmartApi::Error
  end

  it "is caught by rescue WalmartApi::Error" do
    expect { raise described_class, "bad config" }.to raise_error(WalmartApi::Error)
  end
end

RSpec.describe WalmartApi::ApiError do
  subject(:error) { described_class.new(status: 400, body: body, correlation_id: correlation_id) }

  let(:body) { { "errors" => [{ "description" => "Invalid request" }] } }
  let(:correlation_id) { "abc-123-def" }

  it "inherits from WalmartApi::Error" do
    expect(described_class).to be < WalmartApi::Error
  end

  it "exposes status" do
    expect(error.status).to eq(400)
  end

  it "exposes body" do
    expect(error.body).to eq(body)
  end

  it "exposes correlation_id" do
    expect(error.correlation_id).to eq("abc-123-def")
  end

  it "defaults correlation_id to nil" do
    err = described_class.new(status: 400, body: {})
    expect(err.correlation_id).to be_nil
  end

  it "is caught by rescue WalmartApi::Error" do
    expect { raise error }.to raise_error(WalmartApi::Error)
  end

  describe "message generation" do
    it "extracts message from body errors description" do
      expect(error.message).to eq("Invalid request")
    end

    it "extracts message from body errors message field" do
      err = described_class.new(status: 400, body: { "errors" => [{ "message" => "Bad input" }] })
      expect(err.message).to eq("Bad input")
    end

    it "joins multiple error descriptions" do
      multi_body = { "errors" => [{ "description" => "First" }, { "description" => "Second" }] }
      err = described_class.new(status: 400, body: multi_body)
      expect(err.message).to eq("First; Second")
    end

    it "falls back to default message when body is empty hash" do
      err = described_class.new(status: 500, body: {})
      expect(err.message).to eq("Walmart API error (HTTP 500)")
    end

    it "falls back to default message when body is nil" do
      err = described_class.new(status: 502, body: nil)
      expect(err.message).to eq("Walmart API error (HTTP 502)")
    end

    it "falls back to default message when errors array is empty" do
      err = described_class.new(status: 400, body: { "errors" => [] })
      expect(err.message).to eq("Walmart API error (HTTP 400)")
    end

    it "falls back to default message when errors contain no description or message" do
      err = described_class.new(status: 400, body: { "errors" => [{ "code" => "SOME_CODE" }] })
      expect(err.message).to eq("Walmart API error (HTTP 400)")
    end
  end
end

RSpec.describe WalmartApi::AuthenticationError do
  it "inherits from WalmartApi::ApiError" do
    expect(described_class).to be < WalmartApi::ApiError
  end

  it "is caught by rescue WalmartApi::ApiError" do
    err = described_class.new(status: 401, body: {})
    expect { raise err }.to raise_error(WalmartApi::ApiError)
  end

  it "is caught by rescue WalmartApi::Error" do
    err = described_class.new(status: 401, body: {})
    expect { raise err }.to raise_error(WalmartApi::Error)
  end
end

RSpec.describe WalmartApi::AuthorizationError do
  it "inherits from WalmartApi::ApiError" do
    expect(described_class).to be < WalmartApi::ApiError
  end

  it "is caught by rescue WalmartApi::ApiError" do
    err = described_class.new(status: 403, body: {})
    expect { raise err }.to raise_error(WalmartApi::ApiError)
  end
end

RSpec.describe WalmartApi::NotFoundError do
  it "inherits from WalmartApi::ApiError" do
    expect(described_class).to be < WalmartApi::ApiError
  end

  it "is caught by rescue WalmartApi::ApiError" do
    err = described_class.new(status: 404, body: {})
    expect { raise err }.to raise_error(WalmartApi::ApiError)
  end
end

RSpec.describe WalmartApi::ValidationError do
  it "inherits from WalmartApi::ApiError" do
    expect(described_class).to be < WalmartApi::ApiError
  end

  it "is caught by rescue WalmartApi::ApiError" do
    err = described_class.new(status: 400, body: {})
    expect { raise err }.to raise_error(WalmartApi::ApiError)
  end
end

RSpec.describe WalmartApi::RateLimitError do
  it "inherits from WalmartApi::ApiError" do
    expect(described_class).to be < WalmartApi::ApiError
  end

  it "exposes retry_after" do
    err = described_class.new(status: 429, body: {}, retry_after: 30)
    expect(err.retry_after).to eq(30)
  end

  it "defaults retry_after to nil" do
    err = described_class.new(status: 429, body: {})
    expect(err.retry_after).to be_nil
  end

  it "is caught by rescue WalmartApi::ApiError" do
    err = described_class.new(status: 429, body: {}, retry_after: 60)
    expect { raise err }.to raise_error(WalmartApi::ApiError)
  end
end

RSpec.describe WalmartApi::ServerError do
  it "inherits from WalmartApi::ApiError" do
    expect(described_class).to be < WalmartApi::ApiError
  end

  it "is caught by rescue WalmartApi::ApiError" do
    err = described_class.new(status: 500, body: {})
    expect { raise err }.to raise_error(WalmartApi::ApiError)
  end
end
# rubocop:enable RSpec/MultipleDescribes

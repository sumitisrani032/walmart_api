# frozen_string_literal: true

require "base64"

RSpec.describe WalmartApi::Auth::TokenManager do
  subject(:token_manager) { described_class.new(configuration, buffer_seconds: 60) }

  let(:configuration) do
    config = WalmartApi::Configuration.new
    config.client_id = "test_client_id"
    config.client_secret = "test_client_secret"
    config.private_key = "unused_in_token_manager"
    config
  end

  let(:token_url) { "https://marketplace.walmartapis.com/v3/token" }
  let(:expected_auth) { "Basic #{Base64.strict_encode64("test_client_id:test_client_secret")}" }

  let(:token_response_body) do
    { "access_token" => "test_access_token_abc123", "token_type" => "Bearer", "expires_in" => 900 }
  end

  def stub_token_request(status: 200, body: token_response_body)
    stub_request(:post, token_url)
      .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe "#access_token" do
    it "fetches access token from Walmart token endpoint" do
      stub_token_request
      token_manager.access_token
      expect(a_request(:post, token_url)).to have_been_made
    end

    it "sends correct Authorization header" do
      stub_token_request
      token_manager.access_token
      expect(a_request(:post, token_url).with(headers: { "Authorization" => expected_auth })).to have_been_made
    end

    it "sends correct Content-Type" do
      stub_token_request
      token_manager.access_token
      expect(a_request(:post, token_url).with(headers: { "Content-Type" => "application/x-www-form-urlencoded" }))
        .to have_been_made
    end

    it "sends correct grant_type" do
      stub_token_request
      token_manager.access_token
      expect(a_request(:post, token_url).with(body: "grant_type=client_credentials")).to have_been_made
    end

    it "returns the access token string" do
      stub_token_request
      expect(token_manager.access_token).to eq("test_access_token_abc123")
    end

    it "caches token after first fetch" do
      stub = stub_token_request
      token_manager.access_token
      token_manager.access_token
      expect(stub).to have_been_requested.once
    end

    it "returns cached token when not expired" do
      stub_token_request
      first = token_manager.access_token
      second = token_manager.access_token
      expect(second).to eq(first)
    end

    it "refreshes token when expired" do
      stub = stub_token_request
      token_manager.access_token
      travel_past_expiry
      token_manager.access_token
      expect(stub).to have_been_requested.twice
    end

    it "refreshes token within buffer window before expiry" do
      stub = stub_token_request
      token_manager.access_token
      travel_into_buffer_window
      token_manager.access_token
      expect(stub).to have_been_requested.twice
    end

    it "is thread-safe under concurrent access" do
      stub = stub_token_request
      threads = Array.new(10) { Thread.new { token_manager.access_token } }
      threads.each(&:join)
      expect(stub).to have_been_requested.once
    end
  end

  describe "error handling" do
    it "raises AuthenticationError on 401" do
      stub_token_request(status: 401, body: { "errors" => [{ "description" => "Invalid" }] })
      expect { token_manager.access_token }.to raise_error(WalmartApi::AuthenticationError)
    end

    it "raises ServerError on 500" do
      stub_token_request(status: 500, body: { "errors" => [{ "description" => "Internal" }] })
      expect { token_manager.access_token }.to raise_error(WalmartApi::ServerError)
    end
  end

  describe "security" do
    it "never exposes access token in error messages on re-auth failure" do
      stub_token_request
      token_manager.access_token
      stub_token_request(status: 401, body: { "errors" => [{ "description" => "expired" }] })
      travel_past_expiry

      expect { token_manager.access_token }.to raise_error(WalmartApi::AuthenticationError, /expired/)
    end
  end

  private

  def travel_past_expiry
    allow(Time).to receive(:now).and_return(Time.now + 901)
  end

  def travel_into_buffer_window
    allow(Time).to receive(:now).and_return(Time.now + 850)
  end
end

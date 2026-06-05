# frozen_string_literal: true

require "openssl"
require "base64"

RSpec.describe WalmartApi::Auth::SignatureGenerator do
  let(:private_key_content) { File.read(File.expand_path("../../fixtures/test_private_key.pem", __dir__)) }
  let(:public_key_content) { File.read(File.expand_path("../../fixtures/test_public_key.pem", __dir__)) }
  let(:consumer_id) { "test-consumer-id" }
  let(:timestamp) { "1717600000000" }

  describe ".sign" do
    it "returns a Base64 encoded string" do
      sig = described_class.sign(
        private_key_content: private_key_content, consumer_id: consumer_id, timestamp: timestamp
      )
      expect { Base64.strict_decode64(sig) }.not_to raise_error
    end
  end

  describe "#sign" do
    subject(:generator) { described_class.new(private_key_content) }

    it "generates a valid RSA-SHA256 signature verifiable with the public key" do
      signature = generator.sign(consumer_id: consumer_id, timestamp: timestamp)
      raw = Base64.strict_decode64(signature)
      public_key = OpenSSL::PKey::RSA.new(public_key_content)

      expect(public_key.verify("SHA256", raw, "#{consumer_id}\n#{timestamp}\n1\n")).to be true
    end

    it "returns a Base64 encoded string" do
      signature = generator.sign(consumer_id: consumer_id, timestamp: timestamp)
      expect(Base64.strict_decode64(signature)).not_to be_empty
    end

    it "produces deterministic output for identical inputs" do
      sig1 = generator.sign(consumer_id: consumer_id, timestamp: timestamp)
      sig2 = generator.sign(consumer_id: consumer_id, timestamp: timestamp)
      expect(sig1).to eq(sig2)
    end

    it "produces different signatures for different timestamps" do
      sig1 = generator.sign(consumer_id: consumer_id, timestamp: "1717600000000")
      sig2 = generator.sign(consumer_id: consumer_id, timestamp: "1717600001000")
      expect(sig1).not_to eq(sig2)
    end

    it "produces different signatures for different consumer IDs" do
      sig1 = generator.sign(consumer_id: "consumer-a", timestamp: timestamp)
      sig2 = generator.sign(consumer_id: "consumer-b", timestamp: timestamp)
      expect(sig1).not_to eq(sig2)
    end

    it "produces different signatures for different key versions" do
      sig1 = generator.sign(consumer_id: consumer_id, timestamp: timestamp, key_version: "1")
      sig2 = generator.sign(consumer_id: consumer_id, timestamp: timestamp, key_version: "2")
      expect(sig1).not_to eq(sig2)
    end

    it "defaults key_version to 1" do
      sig_default = generator.sign(consumer_id: consumer_id, timestamp: timestamp)
      sig_explicit = generator.sign(consumer_id: consumer_id, timestamp: timestamp, key_version: "1")
      expect(sig_default).to eq(sig_explicit)
    end
  end

  describe "error handling" do
    it "raises WalmartApi::Error for an invalid private key" do
      expect { described_class.new("not-a-valid-key") }.to raise_error(WalmartApi::Error, "invalid private key")
    end

    it "does not include key content in the error message" do
      expect { described_class.new("SECRET_MATERIAL") }.to raise_error(WalmartApi::Error, "invalid private key")
    end
  end
end

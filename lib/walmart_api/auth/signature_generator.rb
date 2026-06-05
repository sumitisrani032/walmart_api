# frozen_string_literal: true

require "openssl"
require "base64"

module WalmartApi
  module Auth
    class SignatureGenerator
      KEY_VERSION = "1"

      def self.sign(private_key_content:, consumer_id:, timestamp:, key_version: KEY_VERSION)
        new(private_key_content).sign(consumer_id: consumer_id, timestamp: timestamp, key_version: key_version)
      end

      def initialize(private_key_content)
        @private_key = parse_private_key(private_key_content)
      end

      def sign(consumer_id:, timestamp:, key_version: KEY_VERSION)
        message = "#{consumer_id}\n#{timestamp}\n#{key_version}\n"
        signature = @private_key.sign("SHA256", message)
        Base64.strict_encode64(signature)
      end

      private

      def parse_private_key(content)
        OpenSSL::PKey::RSA.new(content)
      rescue OpenSSL::PKey::RSAError
        raise WalmartApi::Error, "invalid private key"
      end
    end
  end
end

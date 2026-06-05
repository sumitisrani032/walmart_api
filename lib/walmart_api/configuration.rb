# frozen_string_literal: true

module WalmartApi
  class Configuration
    PRODUCTION_URL = "https://marketplace.walmartapis.com"
    SANDBOX_URL = "https://sandbox.walmartapis.com"

    attr_accessor :client_id, :client_secret, :private_key, :private_key_path,
                  :environment, :channel_type

    def initialize
      @environment = :production
    end

    def base_url
      case environment
      when :production
        PRODUCTION_URL
      when :sandbox
        SANDBOX_URL
      else
        raise ConfigurationError, "unknown environment: #{environment}"
      end
    end

    def resolved_private_key
      return private_key if private_key

      return unless private_key_path

      File.read(private_key_path)
    end

    def validate!
      raise ConfigurationError, "client_id is required" if blank?(client_id)
      raise ConfigurationError, "client_secret is required" if blank?(client_secret)

      validate_private_key!
    end

    private

    def validate_private_key!
      if blank?(private_key) && blank?(private_key_path)
        raise ConfigurationError, "private_key or private_key_path is required"
      end

      return if private_key

      return if File.exist?(private_key_path)

      raise ConfigurationError,
            "private_key_path file not found: #{private_key_path}"
    end

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end
  end
end

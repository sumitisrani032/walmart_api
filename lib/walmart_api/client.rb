# frozen_string_literal: true

module WalmartApi
  class Client
    def initialize(**overrides)
      @configuration = build_configuration(overrides)
      @configuration.validate!

      @token_manager = Auth::TokenManager.new(@configuration)
      private_key = @configuration.resolved_private_key
      @signature_generator = Auth::SignatureGenerator.new(private_key)
      @connection = build_connection
    end

    def orders
      @orders ||= Resources::Orders.new(@connection)
    end

    def inventory
      @inventory ||= Resources::Inventory.new(@connection)
    end

    def items
      @items ||= Resources::Items.new(@connection)
    end

    private

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def build_configuration(overrides)
      override_keys = %i[client_id client_secret private_key private_key_path environment channel_type]
      has_overrides = overrides.slice(*override_keys).values.any? { |v| !v.nil? }
      return WalmartApi.configuration unless has_overrides

      config = Configuration.new
      global = WalmartApi.configuration

      config.client_id = overrides[:client_id] || global.client_id
      config.client_secret = overrides[:client_secret] || global.client_secret
      config.private_key = overrides[:private_key] || global.private_key
      config.private_key_path = overrides[:private_key_path] || global.private_key_path
      config.environment = overrides[:environment] || global.environment
      config.channel_type = overrides[:channel_type] || global.channel_type

      config
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    def build_connection
      Faraday.new(url: @configuration.base_url) do |faraday|
        faraday.use Middleware::Authentication,
                    token_manager: @token_manager,
                    signature_generator: @signature_generator,
                    configuration: @configuration
        faraday.request :json

        faraday.use Middleware::ErrorHandler
        faraday.response :json

        faraday.adapter Faraday.default_adapter
      end
    end
  end
end

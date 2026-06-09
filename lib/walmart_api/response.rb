# frozen_string_literal: true

module WalmartApi
  class Response
    def initialize(data)
      @original_data = data
      @converted_data = convert_keys(data)
    end

    def to_h
      @original_data
    end

    private

    def respond_to_missing?(name, include_private = false)
      @converted_data.key?(name.to_s) || super
    end

    def method_missing(name, *args, &block)
      return super if !args.empty? || block
      return super if writer_or_predicate?(name)

      wrap(@converted_data[name.to_s])
    end

    def writer_or_predicate?(name)
      key = name.to_s
      key.end_with?("=", "!", "?")
    end

    def wrap(value)
      case value
      when Hash then Response.new(value)
      when Array then wrap_array(value)
      else value
      end
    end

    def wrap_array(array)
      array.map { |element| element.is_a?(Hash) ? Response.new(element) : element }
    end

    def convert_keys(hash)
      hash.each_with_object({}) do |(key, value), result|
        result[underscore(key.to_s)] = value
      end
    end

    def underscore(string)
      string
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
    end
  end
end

# frozen_string_literal: true

module WalmartApi
  class PaginatedResponse < Response
    include Enumerable

    attr_reader :next_cursor, :items

    def initialize(data, items:, next_cursor: nil)
      super(data)
      @items = items.map { |item| Response.new(item) }
      @next_cursor = next_cursor
    end

    def to_h
      @original_data
    end

    def each(&)
      @items.each(&)
    end
  end
end

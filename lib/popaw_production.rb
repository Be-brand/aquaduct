# frozen_string_literal: true

require_relative "popaw_production/version"

module PopawProduction
  class Error < StandardError; end

  CHANNELS = [:ordered, :delivered].freeze

  class Order
    class << self
      CHANNELS.each do |channel|
        define_method channel do |id|
          new channel, id
        end
      end
    end

    attr_reader :channel

    def initialize channel, id
      @channel, @id = channel, id
    end
  end

  class OrderChanneler
    def self.channel *a, **kw, &b
      new(*a, **kw, &b).channel
    end

    def initialize *args
      @orders = args
      @delegate = @orders.shift unless @orders.first.is_a? Order
    end

    def channel
      dispatch_orders_to_delegate
      OrdersChannelAggregator.new CHANNELS, @orders
    end

    private

    def dispatch_orders_to_delegate
      @orders.each do |order|
        @delegate.send :"has_been_#{order.channel}!", order
      end
    end

    class OrdersChannelAggregator
      attr_reader :orders

      def initialize channels, orders
        @orders = orders
      end

      CHANNELS.each do |channel|
        define_method :"#{channel}_orders" do
          @orders.filter { |order| order.channel == channel }
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "popaw_production/version"
require_relative "popaw_production/persistence"

module PopawProduction
  class Error < StandardError; end

  CHANNELS = [:ordered, :designed, :delivered].freeze

  class Order
    class << self
      CHANNELS.each do |channel|
        define_method channel do |id|
          new channel, id
        end
      end
    end

    attr_reader :channel, :id

    def initialize channel, id
      @channel, @id = channel, id
    end

    def advance_channel!
      @channel = next_channel
    end

    def next_channel
      current_index = CHANNELS.index channel
      CHANNELS[1 + current_index]
    end
  end

  class OrderChanneler
    def self.channel *a, **kw, &b
      new(*a, **kw, &b).channel
    end

    def initialize *args
      @orders = args
      @delegate = @orders.shift unless @orders.first.is_a? Order
      initialize_persistence
    end

    def channel
      dispatch_orders_to_channels
      OrdersChannelAggregator.new CHANNELS, @orders
    end

    protected

    def initialize_persistence; end
    def already_channeled? order; false end
    def remember_order_was_channeled order; end

    private

    def dispatch_orders_to_channels
      @orders.each do |order|
        dispatch_to_channel order unless already_channeled? order
        if order_channel_completed? order
          order.advance_channel!
          dispatch_to_channel order
        end
      end
    end

    def dispatch_to_channel order
      remember_order_was_channeled order
      @delegate.send :"has_been_#{order.channel}!", order
    end

    def order_channel_completed? order
      @delegate.send :"has_been_#{order.next_channel}?", order
    end

    class OrdersChannelAggregator
      def initialize channels, orders
        @orders = orders
      end

      def all; @orders end

      CHANNELS.each do |channel|
        define_method channel do
          @orders.filter { |order| order.channel == channel }
        end
      end
    end
  end
end

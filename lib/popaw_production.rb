# frozen_string_literal: true

require_relative "popaw_production/version"
require_relative "popaw_production/persistence"

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

    attr_reader :channel, :id

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
      end
    end

    def dispatch_to_channel order
      remember_order_was_channeled order
      @delegate.send :"has_been_#{order.channel}!", order
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

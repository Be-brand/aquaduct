require 'active_support/concern'

module Aquaduct
  module Channelable
    extend ActiveSupport::Concern

    included do
      attr_reader :channel, :id

      # C = channels
      class << self
        CHANNELS.each_value do |channel|
          define_method channel.name do |id|
            new channel, id
          end
        end
      end
    end

    def initialize channel, id
      @channel, @id = channel, id
    end

    def advance!
      @channel = next_channel
    end

    def cancel!
      @channel = cancel_channel
    end

    def next_channel
      @channel.advances_into
    end

    def cancel_channel
      @channel.cancels_into
    end
  end
end

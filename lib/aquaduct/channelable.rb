require 'active_support/concern'

module Aquaduct
  module Channelable
    extend ActiveSupport::Concern

    included do
      @@channels = self.const_get :Channels
      class << self
        @@channels.each_value do |channel|
          define_method channel.name do |id|
            new channel:, id:
          end
        end
      end
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

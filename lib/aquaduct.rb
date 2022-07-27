module Aquaduct
  class Error < StandardError; end
end

require_relative 'aquaduct/version'
require_relative 'aquaduct/channels'
require_relative 'aquaduct/channelable'
require_relative 'aquaduct/channeler'
require_relative 'aquaduct/persistence'

module Aquaduct
  def self.with_channels for_entity = :package, &channel_drawer
    channels = Channels.draw &channel_drawer
    Module.new do
      const_set :CHANNELS, channels

      entity_class_name = for_entity.to_s.camelize
      entity_class = Class.new do
        const_set :CHANNELS, channels
        include Aquaduct::Channelable
      end
      const_set entity_class_name, entity_class

      entity_channeler_class_name = "#{for_entity.to_s.camelize}Channeler"
      entity_channeler_class = Class.new(Aquaduct::Channeler) do
        const_set :CHANNELS, channels
      end
      const_set entity_channeler_class_name, entity_channeler_class
    end
  end
end

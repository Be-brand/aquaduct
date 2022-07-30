module Aquaduct
  def self.with_channels for_entity = :package, &channel_drawer
    channels = Channels.draw &channel_drawer
    Module.new do
      const_set :EntityName, for_entity
      const_set :Channels, channels

      entity_class_name = for_entity.to_s.camelize
      entity_class = Class.new do
        const_set :Channels, channels
        include Aquaduct::Channelable
      end
      const_set entity_class_name, entity_class

      entity_channeler_class_name = "#{for_entity.to_s.camelize}Channeler"
      entity_channeler_class = Class.new(Aquaduct::Channeler) do
        const_set :EntityName, for_entity
        const_set :Channels, channels
        include channels.persistence unless channels.persistence.nil?
      end
      const_set entity_channeler_class_name, entity_channeler_class
    end
  end
end

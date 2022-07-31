require 'active_support/core_ext/string/inflections'
require 'active_model'

module Aquaduct
  def self.with_channels for_entity = :package, &channel_drawer
    channels = Channels.draw &channel_drawer
    Module.new do
      const_set :EntityName, for_entity
      const_set :Channels, channels

      if for_entity.is_a? Symbol or for_entity.is_a? String
        @@entity_class_name = for_entity.to_s.camelize
        @@entity_class = Class.new do
          include ActiveModel::Model
          attr_accessor :id, :channel

          const_set :Channels, channels
          include Aquaduct::Channelable
        end
      else
        @@entity_class_name = for_entity.name
        @@entity_class = Class.new(for_entity) do
          const_set :Channels, channels
          include Aquaduct::Channelable
        end
      end
      const_set @@entity_class_name, @@entity_class

      @@entity_channeler_class_name = "#{for_entity.to_s.camelize}Channeler"
      @@entity_channeler_class = Class.new(Aquaduct::Channeler) do
        const_set :EntityName, for_entity
        const_set :Channels, channels
        include channels.persistence unless channels.persistence.nil?
      end
      const_set @@entity_channeler_class_name, @@entity_channeler_class

      def self.included base
        base.class.define_method :channel do |*a, **kw, &b|
          @@entity_channeler_class.channel *a, **kw, &b
        end
      end
    end
  end
end

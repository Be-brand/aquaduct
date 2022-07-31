# frozen_string_literal: true

require 'aquaduct'
require 'rspec/collection_matchers'
require 'active_support/concern'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after { Aquaduct::Persistence::InMemory.wipe }
end

module TestableChannelable
  extend ActiveSupport::Concern

  # provide random IDs to Order factory methods
  included do
    @@channels = self.const_get :Channels
    class << self
      @@channels.each_value do |channel|
        alias_method :"original_#{channel.name}", channel.name
        define_method channel.name do |*a, **kw, &b|
          send :"original_#{channel.name}", some_id, *a, **kw, &b
        end
      end

      private

      require 'digest'

      def some_id
        Digest::SHA1.hexdigest("some-random-string")[8..16]
      end
    end
  end
end

module TestableAquaduct
  def self.with_channels *a, **kw, &b
    mod = Aquaduct.with_channels *a, **kw, &b

    Module.new do
      include mod

      const_set :Channels, mod::Channels

      package_class_name = const_get(:EntityName).to_s.camelize
      package_class = Class.new(const_get(package_class_name)) do
        include TestableChannelable
      end
      const_set package_class_name, package_class
    end
  end
end

def make_aquaduct_with_channels *a, **kw, &b
  @module = Module.new do
    include(TestableAquaduct.with_channels *a, **kw, &b)
  end
  @entity_name = @module.const_get :EntityName
  entity = @entity_name.to_s.camelize.to_sym
  @package_class = @module.const_get entity
  @package_channeler_class = @module.const_get :"#{entity}Channeler"
end

def channel *a, **kw, &b
  @channeled = @package_channeler_class.channel *a, **kw, &b
end

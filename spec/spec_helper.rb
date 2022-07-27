# frozen_string_literal: true

require 'aquaduct'
require 'rspec/collection_matchers'
require 'active_support/concern'
require 'active_support/core_ext/string/inflections'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after(:each) { Aquaduct::Persistence::InMemory.wipe }
end

module TestableChannelable
  extend ActiveSupport::Concern

  # provide random IDs to Order factory methods
  included do
    C = self.const_get :CHANNELS
    class << self
      C.each_value do |channel|
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

      const_set :CHANNELS, mod::CHANNELS

      package_class = Class.new(const_get(:Package)) do
        include TestableChannelable
      end
      const_set :Package, package_class

      package_channeler_class = Class.new(const_get(:PackageChanneler)) do
        include Aquaduct::Persistence::InMemory
      end
      const_set :PackageChanneler, package_channeler_class
    end
  end
end

module Aquaduct
  class Error < StandardError; end
end

require_relative 'aquaduct/version'
require_relative 'aquaduct/channels'
require_relative 'aquaduct/channelable'
require_relative 'aquaduct/channeler'
require_relative 'aquaduct/persistence'
require_relative 'aquaduct/factory'

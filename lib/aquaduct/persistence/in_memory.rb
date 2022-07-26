module Aquaduct::Persistence
  module InMemory
    def self.memory
      @memory or @memory = {}
    end

    def self.wipe
      @memory = {}
    end

    protected

    def remember_package_was_channeled package
      memory[package.id] ||= []
      memory[package.id] << package.channel
    end

    def already_channeled? package
      memory.key?(package.id) and memory[package.id].include? package.channel
    end

    private def memory
      InMemory.memory
    end
  end
end

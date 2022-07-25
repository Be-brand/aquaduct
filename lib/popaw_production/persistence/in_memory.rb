module PopawProduction::Persistence
  module InMemory
    def self.memory
      @memory or @memory = {}
    end

    def self.wipe
      @memory = {}
    end

    protected

    def remember_order_was_channeled order
      memory[order.id] ||= []
      memory[order.id] << order.channel
    end

    def already_channeled? order
      memory.key?(order.id) and memory[order.id].include? order.channel
    end

    private def memory
      InMemory.memory
    end
  end
end

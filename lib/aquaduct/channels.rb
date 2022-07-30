module Aquaduct
  module Channels
    class Error < Aquaduct::Error; end
    class DrawCannotStartWithAndThenError < Error; end

    def self.draw &drawer
      if drawer.nil?
        Drawer.run {}
      else
        Drawer.run &drawer
      end
    end
  end

  private

  class Drawer
    def self.run &drawer
      instance = new
      instance.instance_eval &drawer
      instance.send :result # only way to call non-public method
    end

    def initialize
      @draw_started = false
      @sequences = []
      @cancel_channels = []
    end

    def persist persistence
      persistence = Aquaduct::Persistence.const_get persistence.to_s.camelize
      @persistence = persistence
    end

    def and_then *a, **kw, &b
      raise Channels::DrawCannotStartWithAndThenError unless @draw_started
      advance_through *a, **kw, &b
    end

    def advance_through channels, cancel_into: :cancelled
      @draw_started = true
      @cancel_channels << cancel_into
      channels.each { |c| @sequences << [c, cancel_into] }
    end

    private

    def result
      result = prepare_result_channels
      result.instance_variable_set :@persistence, @persistence
      def result.persistence
        @persistence
      end
      result
    end

    def prepare_result_channels
      result = {}
      @sequences.each_with_index &register_channel_into(result)
      @cancel_channels.each do |channel_name|
        channel = Channel.new channel_name
        result[channel_name] = channel
      end
      result.instance_variable_set :@sequences, @sequences
      def result.sequence
        @sequences.map do |(channel, _)|
          self[channel]
        end
      end
      result
    end

    def register_channel_into result
      lambda do |(channel, cancel_into), index|
        next_in_sequences = @sequences[index + 1]
        next_channel = next_in_sequences[0] unless next_in_sequences.nil?
        result[channel] = Channel.new channel, cancel_into:, next_channel:
      end
    end
  end

  class Channel
    attr_reader :name

    def initialize(name, next_channel: nil, cancel_into: nil)
      @@channels ||= {}
      @@channels[name] = self
      @name = name
      @advances_into = next_channel
      @cancels_into = cancel_into
    end

    def advances_into
      @@channels[@advances_into]
    end

    def cancels_into
      @@channels[@cancels_into]
    end
  end
end

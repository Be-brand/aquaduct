module Aquaduct
  class Channeler
    def self.channel *a, **kw, &b
      new(*a, **kw, &b).channel
    end

    def initialize delegate, *packages
      @packages = packages
      @delegate = delegate
      initialize_persistence
    end

    def channel
      dispatch_packages_to_channels
      aggregate_channeled_packages
    end

    protected

    def initialize_persistence; end
    def package_already_channeled? _package; end
    def remember_package_was_channeled _package; end

    private

    def dispatch_packages_to_channels
      @packages.each do |package|
        dispatch_to_channel package unless already_channeled? package
        cancel_package package if package_cancelled? package
        advance_package package if package_completed? package
      end
    end

    def cancel_package package
      package.cancel!
      dispatch_to_channel package
    end

    def advance_package package
      package.advance!
      dispatch_to_channel package
    end

    def dispatch_to_channel package
      remember_package_was_channeled package
      delegate :"#{package.channel.name}!", package
    end

    def already_channeled? package
      true == package_already_channeled?(package)
    end

    def package_cancelled? package
      return false if package.cancel_channel.nil?
      question = :"#{package.cancel_channel.name}?"
      true == delegate(question, package)
    end

    def package_completed? package
      return false if package.next_channel.nil?
      question = :"#{package.next_channel.name}?"
      true == delegate(question, package)
    end

    def delegate name, *a, **kw, &b
      @delegate.send name, *a, **kw, &b if @delegate.respond_to? name
    end

    def aggregate_channeled_packages
      channels = self.class.const_get :Channels
      Class.new do
        def initialize packages
          @packages = packages
        end

        def all; @packages end

        channels.keys.each do |channel_name|
          define_method channel_name do
            @packages.filter { |package| package.channel.name == channel_name }
          end
        end
      end.new @packages
    end
  end
end

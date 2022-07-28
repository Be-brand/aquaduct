module Aquaduct::Persistence
  module Delegated
    protected

    def remember_package_was_channeled package
      @delegate.remember_package_was_channeled package
    end

    def package_already_channeled? package
      @delegate.package_already_channeled? package
    end
  end
end

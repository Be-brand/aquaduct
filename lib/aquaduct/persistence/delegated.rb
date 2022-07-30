module Aquaduct::Persistence
  module Delegated
    protected

    def remember_package_was_channeled package
      delegate :remember_package_was_channeled, package
    end

    def package_already_channeled? package
      delegate :package_already_channeled?, package
    end

    private

    def delegate method, package
      custom_entity_name = self.class.const_get :EntityName
      custom_name = method.to_s.gsub('package', custom_entity_name.to_s).to_sym
      method = custom_name if @delegate.respond_to? custom_name
      @delegate.send method, package
    end
  end
end

module Aquaduct::Persistence::Spec
  RSpec.describe Aquaduct::Persistence do
    module Testable
      include(TestableAquaduct.with_channels do
                persist :delegated

                advance_through %i[once twice]
              end)
    end

    let(:channeled) { @channeled }
    let(:delegate) { double }

    def channel *a, **kw, &b
      @channeled = Testable::PackageChanneler.channel *a, **kw, &b
    end

    before(:each) do
      @package = Testable::Package.once
    end

    after(:each) do
      channel delegate, @package
    end

    it "persists a channeled package unless it's persisted" do
      expect(delegate).to receive(:package_already_channeled?).and_return false
      expect(delegate).to receive(:remember_package_was_channeled)
                            .once.with @package
    end

    it "doesn't persist a channeled package if it's persisted" do
      expect(delegate).to receive(:package_already_channeled?).and_return true
      expect(delegate).to_not receive(:remember_package_was_channeled)
    end
  end
end

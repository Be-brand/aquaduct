# TODO: I couldn't find a clean way to eliminate the duplication
# Probably the best thing to do would be to go dynamic modules all the way,
# and load the classes therein into RSpec let statements. This would mean
# the tests won't refer to the classes by name, but what can you do.

module Aquaduct::Persistence::Spec
  RSpec.describe Aquaduct::Persistence do
    module Testable
      include(TestableAquaduct.with_channels do
                persist :delegated

                advance_through %i[first second]
              end)
    end

    let(:channeled) { @channeled }
    let(:delegate) { double :cancelled? => nil, :first! => nil, :second? => nil }

    def channel *a, **kw, &b
      @channeled = Testable::PackageChanneler.channel *a, **kw, &b
    end

    before(:each) do
      @package = Testable::Package.first
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

module Aquaduct::Persistence::Spec::CustomPackageName
  RSpec.describe Aquaduct::Persistence do
    module Testable
      include(TestableAquaduct.with_channels(:order) do
                persist Aquaduct::Persistence::Delegated

                advance_through %i[first second]
              end)
    end

    before(:each) do
      @delegate = double :cancelled? => nil, :first! => nil, :second? => nil
    end

    def channel *a, **kw, &b
      @channeled = Testable::OrderChanneler.channel *a, **kw, &b
    end

    before(:each) do
      @package = Testable::Order.first
    end

    after(:each) do
      channel @delegate, @package
    end

    it "uses the standard name when that's all the persistence supports" do
      expect(@delegate).to receive(:package_already_channeled?).once
      expect(@delegate).to receive(:remember_package_was_channeled).once
    end

    it 'uses the custom name when the persistence supports it' do
      [
        expect(@delegate).to(receive(:package_already_channeled?)),
        expect(@delegate).to(receive(:remember_package_was_channeled))
      ].each { |e| e.exactly(0).times }
      expect(@delegate).to receive(:order_already_channeled?).once
      expect(@delegate).to receive(:remember_order_was_channeled).once
    end
  end
end

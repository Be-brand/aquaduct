RSpec.describe Aquaduct::Persistence do
  let(:delegate) { double :cancelled? => nil, :first! => nil, :second? => nil }

  before do
    @package = @package_class.first
  end

  after do
    channel delegate, @package
  end

  context do
    before(:context) do
      make_aquaduct_with_channels do
        persist :delegated

        advance_through %i[first second]
      end
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

  context 'custom package name' do
    before(:context) do
      make_aquaduct_with_channels(:order) do
        persist Aquaduct::Persistence::Delegated

        advance_through %i[first second]
      end
    end

    it "uses the standard name when that's all the persistence supports" do
      expect(delegate).to receive(:package_already_channeled?).once
      expect(delegate).to receive(:remember_package_was_channeled).once
    end

    it 'uses the custom name when the persistence supports it' do
      [
        expect(delegate).to(receive(:package_already_channeled?)),
        expect(delegate).to(receive(:remember_package_was_channeled))
      ].each { |e| e.exactly(0).times }
      expect(delegate).to receive(:order_already_channeled?).once
      expect(delegate).to receive(:remember_order_was_channeled).once
    end
  end
end

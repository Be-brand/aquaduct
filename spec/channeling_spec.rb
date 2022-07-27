# frozen_string_literal: true

module Testable
  include(TestableAquaduct.with_channels do
    advance_through %i[ordered packaged], cancel_into: :cancelled
    and_then %i[delivered], cancel_into: :return_requested
  end)
end

RSpec.describe Testable::PackageChanneler do
  let(:channeled) { @channeled }
  let(:delegate) { spy }

  def channel *a, **kw, &b
    @channeled = Testable::PackageChanneler.channel *a, **kw, &b
  end

  it 'does nothing given no orders' do
    channel delegate
    expect(channeled.all).to have(0).orders
  end

  context 'notifying and advancing from ordered' do
    let(:order) { Testable::Package.ordered }

    it 'notifies about an order' do
      expect(delegate).to receive(:ordered!).with order
      channel delegate, order
    end

    it 'only notifies once per order' do
      expect(delegate).to receive(:ordered!).once
      channel delegate, order
      channel delegate, order
    end

    it 'asks if an order has been packaged' do
      expect(delegate).to receive(:packaged?).once
      channel delegate, order
    end

    it "advances an order when it has been packaged" do
      expect(delegate).to receive(:packaged?).and_return true
      expect(delegate).to receive(:packaged!).once
      channel delegate, order
      expect(channeled.ordered).to have(0).orders
      expect(channeled.packaged).to have(1).order
    end
  end

  context 'cancelling' do
    let(:order) { Testable::Package.ordered }

    it 'asks if an order has been cancelled' do
      expect(delegate).to receive(:cancelled?).once
      channel delegate, order
    end

    it 'cancels an order when it has been cancelled' do
      expect(delegate).to receive(:cancelled?).and_return true
      expect(delegate).to receive(:cancelled!).once
      channel delegate, order
      expect(channeled.ordered).to have(0).orders
      expect(channeled.cancelled).to have(1).order
    end

    it 'asks nothing when it is cancelled' do
      delegate = double # raises when sent nonexistent methods
      expect(delegate).to receive(:cancelled!).once
      expect { channel delegate, Testable::Package.cancelled }
        .to_not raise_error
    end

    it 'cancels into return_requested' do
      expect(delegate).to receive(:return_requested?).once.and_return true
      expect(delegate).to receive(:return_requested!).once
      channel delegate, Testable::Package.delivered
    end
  end
end
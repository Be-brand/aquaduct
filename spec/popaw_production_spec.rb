# frozen_string_literal: true

RSpec.describe PopawProduction do
  it 'has a version number' do
    expect(PopawProduction::VERSION).not_to be nil
  end
end

module PopawProduction
  class PopawProduction::Order
    # provide random IDs to Order factory methods
    class << self
      require 'digest'

      def some_id
        Digest::SHA1.hexdigest("some-random-string")[8..16]
      end

      CHANNELS.each do |channel|
        alias_method :"original_#{channel}", channel
        define_method channel do |*a, **kw, &b|
          send :"original_#{channel}", some_id, *a, **kw, &b
        end
      end
    end
  end

  class TestableOrderChanneler < PopawProduction::OrderChanneler
    include PopawProduction::Persistence::InMemory
  end

  RSpec.describe TestableOrderChanneler do
    after(:each) { PopawProduction::Persistence::InMemory.wipe }

    it 'does nothing given no orders' do
      channel
      expect(channeled.all).to have(0).orders
    end

    context 'ordered' do
      let(:delegate) { spy }
      let(:order) { Order.ordered }

      it 'notifies designers about the order' do
        expect(delegate).to receive(:has_been_ordered!).with order
        channel delegate, order
      end

      it 'only notifies once per order' do
        expect(delegate).to receive(:has_been_ordered!).once
        channel delegate, order
        channel delegate, order
      end

      it 'asks if order has been designed' do
        expect(delegate).to receive(:has_been_designed?).once
        channel delegate, order
      end

      it "notifies order has been designed when it's been designed" do
        expect(delegate).to receive(:has_been_designed?).and_return true
        expect(delegate).to receive(:has_been_designed!)
        channel delegate, order
        expect(channeled.ordered).to have(0).orders
        expect(channeled.designed).to have(1).order
      end
    end

    let(:channeled) { @channeled }

    def channel *a, **kw, &b
      @channeled = subject.class.channel *a, **kw, &b
    end
  end
end

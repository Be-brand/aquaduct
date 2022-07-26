# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/core_ext/string/inflections'

RSpec.describe Aquaduct do
  it 'has a version number' do
    expect(Aquaduct::VERSION).not_to be nil
  end
end

module TestableChannelable
  extend ActiveSupport::Concern

  # provide random IDs to Order factory methods
  included do
    C = self.const_get :CHANNELS
    class << self
      C.each_value do |channel|
        alias_method :"original_#{channel.name}", channel.name
        define_method channel.name do |*a, **kw, &b|
          send :"original_#{channel.name}", some_id, *a, **kw, &b
        end
      end

      private

      require 'digest'

      def some_id
        Digest::SHA1.hexdigest("some-random-string")[8..16]
      end
    end
  end
end

module Testable
  mod = Aquaduct.with_channels do
    advance_through %i[ordered packaged], cancel_into: :cancelled
    and_then %i[delivered], cancel_into: :return_requested
  end

  class mod::Package
    include TestableChannelable
  end

  class mod::PackageChanneler
    include Aquaduct::Persistence::InMemory
  end

  include mod
end

RSpec.describe Testable::PackageChanneler do
  after(:each) { Aquaduct::Persistence::InMemory.wipe }

  let(:channeled) { @channeled }
  let(:delegate) { spy }

  def channel *a, **kw, &b
    @channeled = Testable::PackageChanneler.channel *a, **kw, &b
  end

  it 'does nothing given no orders' do
    channel delegate
    expect(channeled.all).to have(0).orders
  end

  context 'ordered' do
    let(:order) { Testable::Package.ordered }

    it 'notifies designers about an order' do
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
  end

  context 'cancelled' do
    it 'asks nothing when it is cancelled' do
      delegate = double # raises when sent nonexistent methods
      expect(delegate).to receive(:cancelled!).once
      expect { channel delegate, Testable::Package.cancelled }
        .to_not raise_error
    end
  end

  context 'delivered' do
    let(:order) { Testable::Package.delivered }

    it 'cancels into return_requested' do
      expect(delegate).to receive(:return_requested?).once.and_return true
      expect(delegate).to receive(:return_requested!).once
      channel delegate, order
    end
  end
end

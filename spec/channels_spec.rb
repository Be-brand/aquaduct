module Aquaduct
  RSpec.describe Channels do
    RSpec::Matchers.define :cancel_into do |expected|
      match do |actual|
        values_match? actual.cancels_into.name, expected
      end
    end

    RSpec::Matchers.define :advance_into do |expected|
      match do |actual|
        values_match? actual.advances_into.name, expected
      end
    end

    RSpec::Matchers.define :be_cancellable do
      match do |actual|
        not actual.cancels_into.nil?
      end
    end

    RSpec::Matchers.define :be_advanceable do
      match do |actual|
        not actual.advances_into.nil?
      end
    end

    it 'draws empty hash given no channels' do
      expect(Channels.draw).to eq({})
    end

    it 'draws simple sequence with explicit cancel channel' do
      channels = Channels.draw do
        advance_through %i[first last], cancel_into: :cancelled
      end
      %i[first last].each do |channel|
        expect(channels[channel]).not_to be_nil
        expect(channels[channel]).to cancel_into :cancelled
      end
      expect(channels[:first]).to advance_into :last
    end

    it 'cancels into the :cancelled channel by default' do
      channels = Channels.draw do
        advance_through %i[channel]
      end
      expect(channels[:channel]).to cancel_into :cancelled
    end

    it 'advances through multiple sequences' do
      channels = Channels.draw do
        advance_through %i[first]
        and_then %i[second]
      end
      expect(channels[:first]).to advance_into :second
    end

    it 'cancels into appropriate channels for each sequence' do
      channels = Channels.draw do
        advance_through %i[first], cancel_into: :first_cancel
        and_then %i[second], cancel_into: :second_cancel
      end
      %i[first second].each do |channel|
        expect(channels[channel]).to cancel_into :"#{channel}_cancel"
      end
    end

    it "doesn't advance past last channel" do
      channels = Channels.draw do
        advance_through %i[channel]
      end
      expect(channels[:channel]).to_not be_advanceable
    end

    it 'cancel channel may not be cancellable' do
      channels = Channels.draw do
        advance_through %i[channel], cancel_into: :cancelled
      end
      expect(channels[:cancelled]).to_not be_cancellable
    end

    it 'may only begin channel sequence with advance_through and not and_then' do
      expect { Channels.draw { and_then [] } }
        .to raise_error Channels::DrawCannotStartWithAndThenError
    end

    # Channels.draw do
    #   advance_through %i[ordered designed produced], cancel_into: :cancelled
    #   and_then %i[shipped delivered], cancel_into: :requested_return
    # end
  end
end

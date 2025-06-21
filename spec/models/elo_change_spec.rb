# frozen_string_literal: true

require 'spec_helper'

describe EloChange do
  let(:channel) { Fabricate(:channel) }
  let(:user) { Fabricate(:user, channel: channel) }
  let(:match) { Fabricate(:match, channel: channel) }
  let(:elo_change) { described_class.new(match: match, user: user, elo: 100, delta: 25) }

  describe '#channel_elo' do
    it 'returns the sum of elo and channel elo' do
      expect(elo_change.channel_elo).to eq 100
    end

    it 'handles zero channel elo' do
      channel.update_attributes!(elo: 0)
      expect(elo_change.channel_elo).to eq 100
    end

    it 'handles negative channel elo' do
      channel.update_attributes!(elo: -50)
      expect(elo_change.channel_elo).to eq 50
    end
  end

  describe '#new_channel_elo' do
    it 'returns the sum of new_elo and channel elo' do
      channel.update_attributes!(elo: 50)
      expect(elo_change.new_channel_elo).to eq 175
    end

    it 'handles negative delta' do
      channel.update_attributes!(elo: 50)
      elo_change.delta = -25
      expect(elo_change.new_channel_elo).to eq 125
    end

    it 'handles zero delta' do
      channel.update_attributes!(elo: 50)
      elo_change.delta = 0
      expect(elo_change.new_channel_elo).to eq 150
    end

    it 'handles decimal delta values' do
      channel.update_attributes!(elo: 50)
      elo_change.delta = 12.5
      expect(elo_change.new_channel_elo).to eq 162.5
    end
  end

  describe '#to_s' do
    it 'formats positive delta with plus sign' do
      expect(elo_change.to_s).to eq '+25 → 125'
    end

    it 'formats negative delta with minus sign' do
      elo_change.delta = -25
      expect(elo_change.to_s).to eq '-25 → 75'
    end

    it 'uses channel elo' do
      channel.update_attributes!(elo: 1000)
      expect(elo_change.to_s).to eq '+25 → 1125'
    end

    it 'handles delta equal to new positive elo' do
      elo_change.delta = 48
      elo_change.elo = 0
      expect(elo_change.to_s).to eq '+48'
    end

    it 'handles delta equal to new negative elo' do
      elo_change.delta = -48
      elo_change.elo = 0
      expect(elo_change.to_s).to eq '-48'
    end

    it 'handles delta equal to new negative elo with channel elo' do
      channel.update_attributes!(elo: 1000)
      elo_change.delta = -48
      elo_change.elo = 0
      expect(elo_change.to_s).to eq '-48 → 952'
    end

    it 'handles channel delta' do
      channel.update_attributes!(elo: 100)
      elo_change.delta = -48
      elo_change.elo = -52
      expect(elo_change.to_s).to be_nil
    end

    it 'handles positive elo and zero delta when new_channel_elo is non-zero' do
      elo_change.delta = 0
      channel.update_attributes!(elo: 100)
      expect(elo_change.to_s).to eq '+200'
    end

    it 'handles negative elo and zero delta when new_channel_elo is non-zero' do
      elo_change.delta = 0
      channel.update_attributes!(elo: -200)
      expect(elo_change.to_s).to eq '-100'
    end

    it 'handles zero delta when new_channel_elo is zero' do
      elo_change.delta = 0
      elo_change.elo = 0
      channel.update_attributes!(elo: 0)
      expect(elo_change.to_s).to be_nil
    end

    it 'handles decimal delta values by rounding to integer' do
      elo_change.delta = 12.7
      expect(elo_change.to_s).to eq '+12 → 112'
    end

    it 'handles negative decimal delta values by rounding to integer' do
      elo_change.delta = -12.7
      expect(elo_change.to_s).to eq '-12 → 87'
    end

    it 'handles very small delta values (less than 1)' do
      elo_change.delta = 0.5
      expect(elo_change.to_s).to eq '+100'
    end

    it 'handles very small negative delta values (greater than -1)' do
      elo_change.delta = -0.5
      expect(elo_change.to_s).to eq '+99'
    end
  end
end

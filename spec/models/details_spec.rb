require 'spec_helper'

describe Details do
  describe '#parse_s' do
    it 'returns nil for nil' do
      expect(Details.parse_s(nil)).to be_nil
    end

    it 'returns elo' do
      expect(Details.parse_s('elo')).to eq(Details::ELO)
    end

    it 'raise an error on an invalid value' do
      expect { Details.parse_s('invalid') }.to raise_error SlackGamebot::Error, 'Invalid value: invalid, possible values are elo and leaderboard.'
    end
  end
end

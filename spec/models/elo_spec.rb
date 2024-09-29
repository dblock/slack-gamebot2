# frozen_string_literal: true

require 'spec_helper'

describe Elo do
  describe '#channel_elo' do
    it 'is rounded average of elo' do
      expect(described_class.team_elo([User.new(elo: 1)])).to eq 1
      expect(described_class.team_elo([User.new(elo: 1), User.new(elo: 2)])).to eq 1.5
      expect(described_class.team_elo([User.new(elo: 3), User.new(elo: 3), User.new(elo: 4)])).to eq 3.33
    end
  end
end

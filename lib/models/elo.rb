# frozen_string_literal: true

module Elo
  ALGORITHMS = %w[adaptive standard].freeze

  def self.team_elo(players)
    (players.sum(&:elo).to_f / players.count).round(2)
  end
end

require_relative 'elo/adaptive'
require_relative 'elo/standard'

# Keep top-level constants for backward compatibility
Elo::MAX_TAU = Elo::Adaptive::MAX_TAU
Elo::DELTA_TAU = Elo::Adaptive::DELTA_TAU

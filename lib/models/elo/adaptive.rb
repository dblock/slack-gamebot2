# frozen_string_literal: true

module Elo
  # The adaptive algorithm reduces ELO volatility as players gain experience,
  # using a tau decay factor (decay^tau) that grows with each match played.
  module Adaptive
    DELTA_TAU = 0.94
    MAX_TAU = 11

    def self.calculate(winners, losers, options = {})
      winners_delta = []
      losers_delta = []
      winners_elo = Elo.team_elo(winners)
      losers_elo = Elo.team_elo(losers)

      losers_ratio = losers.any? ? [winners.size.to_f / losers.size, 1].min : 1
      winners_ratio = winners.any? ? [losers.size.to_f / winners.size, 1].min : 1

      tied = options[:tied]
      score_ratio = options[:score_ratio]
      decay = options[:decay] || DELTA_TAU

      ratio = if winners_elo == losers_elo && tied
                0
              elsif tied
                0.5
              else
                score_ratio
              end

      winners.each do |winner|
        e = 100 - (1.0 / (1.0 + (10.0**((losers_elo - winner.elo) / 400.0))) * 100)
        winner.tau = [winner.tau + 0.5, MAX_TAU].min
        winners_delta << (e * ratio * (decay**winner.tau) * winners_ratio)
      end

      losers.each do |loser|
        e = 100 - (1.0 / (1.0 + (10.0**((loser.elo - winners_elo) / 400.0))) * 100)
        loser.tau = [loser.tau + 0.5, MAX_TAU].min
        losers_delta << (e * ratio * (decay**loser.tau) * losers_ratio)
      end

      [winners_delta, losers_delta]
    end
  end
end

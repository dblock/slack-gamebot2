# frozen_string_literal: true

module Elo
  # The standard algorithm implements the textbook Elo formula: K * (S - E),
  # where K is a fixed constant, S is the actual score (1, 0.5, or 0),
  # and E is the expected score based on the rating difference.
  module Standard
    DEFAULT_K = 32

    def self.calculate(winners, losers, options = {})
      winners_delta = []
      losers_delta = []
      winners_elo = Elo.team_elo(winners)
      losers_elo = Elo.team_elo(losers)

      losers_ratio = losers.any? ? [winners.size.to_f / losers.size, 1].min : 1
      winners_ratio = winners.any? ? [losers.size.to_f / winners.size, 1].min : 1

      k = options[:k] || DEFAULT_K
      tied = options[:tied]

      winner_score = tied ? 0.5 : 1
      loser_score = tied ? 0.5 : 0

      winners.each do |winner|
        e = 1.0 / (1.0 + (10.0**((losers_elo - winner.elo) / 400.0)))
        winners_delta << (k * (winner_score - e) * winners_ratio)
      end

      losers.each do |loser|
        e = 1.0 / (1.0 + (10.0**((winners_elo - loser.elo) / 400.0)))
        losers_delta << (k * (loser_score - e) * losers_ratio).abs
      end

      [winners_delta, losers_delta]
    end
  end
end

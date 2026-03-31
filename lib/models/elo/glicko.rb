# frozen_string_literal: true

module Elo
  # Glicko-1 rating system (Glickman, 1995).
  # Extends Elo by tracking rating deviation (RD) per player.
  # A higher RD means more uncertainty; it shrinks as more games are played.
  module Glicko
    DEFAULT_RD = 350.0
    Q = Math.log(10) / 400.0

    def self.g(rd)
      1.0 / Math.sqrt(1.0 + (3.0 * (Q**2) * (rd**2) / (Math::PI**2)))
    end

    def self.expected_score(r, r_j, rd_j)
      1.0 / (1.0 + (10.0**(-g(rd_j) * (r - r_j) / 400.0)))
    end

    def self.calculate(winners, losers, options = {})
      winners_delta = []
      losers_delta  = []

      tied = options[:tied]
      winner_score = tied ? 0.5 : 1.0
      loser_score  = tied ? 0.5 : 0.0

      losers_ratio  = losers.any?  ? [winners.size.to_f / losers.size, 1].min : 1
      winners_ratio = winners.any? ? [losers.size.to_f / winners.size, 1].min : 1

      opp_winners_elo = Elo.team_elo(losers)
      opp_losers_elo  = Elo.team_elo(winners)
      opp_winners_rd  = losers.empty?  ? DEFAULT_RD : losers.sum { |p| p.rd.to_f } / losers.size
      opp_losers_rd   = winners.empty? ? DEFAULT_RD : winners.sum { |p| p.rd.to_f } / winners.size

      winners.each do |winner|
        r   = winner.elo.to_f
        rd  = winner.rd.to_f
        g_j = g(opp_winners_rd)
        e_j = expected_score(r, opp_winners_elo, opp_winners_rd)
        d2  = 1.0 / ((Q**2) * (g_j**2) * e_j * (1.0 - e_j))

        new_r  = r + ((Q / ((1.0 / (rd**2)) + (1.0 / d2))) * g_j * (winner_score - e_j) * winners_ratio)
        new_rd = Math.sqrt(1.0 / ((1.0 / (rd**2)) + (1.0 / d2)))

        winner.rd = new_rd
        winners_delta << (new_r - r)
      end

      losers.each do |loser|
        r   = loser.elo.to_f
        rd  = loser.rd.to_f
        g_j = g(opp_losers_rd)
        e_j = expected_score(r, opp_losers_elo, opp_losers_rd)
        d2  = 1.0 / ((Q**2) * (g_j**2) * e_j * (1.0 - e_j))

        new_r  = r + ((Q / ((1.0 / (rd**2)) + (1.0 / d2))) * g_j * (loser_score - e_j) * losers_ratio)
        new_rd = Math.sqrt(1.0 / ((1.0 / (rd**2)) + (1.0 / d2)))

        loser.rd = new_rd
        losers_delta << (r - new_r).abs
      end

      [winners_delta, losers_delta]
    end
  end
end

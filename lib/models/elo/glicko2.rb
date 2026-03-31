# frozen_string_literal: true

module Elo
  # Glicko-2 rating system (Glickman, 2001).
  # Extends Glicko by adding per-player volatility (σ), which measures
  # how consistent a player's performance is. The system constant τ controls
  # how quickly volatility can change.
  module Glicko2
    DEFAULT_RD         = 350.0
    DEFAULT_VOLATILITY = 0.06
    DEFAULT_TAU        = 0.5
    SCALE              = 173.7178

    def self.g(phi)
      1.0 / Math.sqrt(1.0 + (3.0 * (phi**2) / (Math::PI**2)))
    end

    def self.expected_score(mu, mu_j, phi_j)
      1.0 / (1.0 + Math.exp(-g(phi_j) * (mu - mu_j)))
    end

    # Illinois algorithm to find new volatility σ'.
    def self.new_volatility(sigma, phi, v, delta_raw, tau)
      a  = Math.log(sigma**2)
      f  = lambda do |x|
        exp_x = Math.exp(x)
        numer = exp_x * ((delta_raw**2) - (phi**2) - v - exp_x)
        denom = 2.0 * (((phi**2) + v + exp_x)**2)
        (numer / denom) - ((x - a) / (tau**2))
      end

      b = if delta_raw**2 > (phi**2) + v
            Math.log((delta_raw**2) - (phi**2) - v)
          else
            k = 1
            k += 1 while f.call(a - (k * tau)).negative?
            a - (k * tau)
          end

      fa = f.call(a)
      fb = f.call(b)

      100.times do
        break if (b - a).abs < 1e-6

        c  = a + ((a - b) * fa / (fb - fa))
        fc = f.call(c)

        if (fc * fb).negative?
          a  = b
          fa = fb
        else
          fa /= 2.0
        end

        b  = c
        fb = fc
      end

      Math.exp(a / 2.0)
    end

    def self.calculate(winners, losers, options = {})
      winners_delta = []
      losers_delta  = []

      tied = options[:tied]
      winner_score = tied ? 0.5 : 1.0
      loser_score  = tied ? 0.5 : 0.0
      tau          = options[:glicko2_tau] || DEFAULT_TAU

      losers_ratio  = losers.any?  ? [winners.size.to_f / losers.size, 1].min : 1
      winners_ratio = winners.any? ? [losers.size.to_f / winners.size, 1].min : 1

      opp_winners_elo = Elo.team_elo(losers)
      opp_losers_elo  = Elo.team_elo(winners)
      opp_winners_rd  = losers.empty?  ? DEFAULT_RD : losers.sum { |p| p.rd.to_f } / losers.size
      opp_losers_rd   = winners.empty? ? DEFAULT_RD : winners.sum { |p| p.rd.to_f } / winners.size

      opp_winners_mu  = opp_winners_elo.to_f / SCALE
      opp_winners_phi = opp_winners_rd.to_f  / SCALE
      opp_losers_mu   = opp_losers_elo.to_f  / SCALE
      opp_losers_phi  = opp_losers_rd.to_f   / SCALE

      winners.each do |winner|
        mu    = winner.elo.to_f        / SCALE
        phi   = winner.rd.to_f         / SCALE
        sigma = winner.volatility.to_f

        g_j     = g(opp_winners_phi)
        e_j     = expected_score(mu, opp_winners_mu, opp_winners_phi)
        v       = 1.0 / ((g_j**2) * e_j * (1.0 - e_j))
        d_raw   = v * g_j * (winner_score - e_j)

        sigma_prime = new_volatility(sigma, phi, v, d_raw, tau)
        phi_star    = Math.sqrt((phi**2) + (sigma_prime**2))
        new_phi     = 1.0 / Math.sqrt((1.0 / (phi_star**2)) + (1.0 / v))
        new_mu      = mu + ((new_phi**2) * g_j * (winner_score - e_j) * winners_ratio)

        winner.rd         = new_phi * SCALE
        winner.volatility = sigma_prime
        winners_delta << ((new_mu - mu) * SCALE)
      end

      losers.each do |loser|
        mu    = loser.elo.to_f        / SCALE
        phi   = loser.rd.to_f         / SCALE
        sigma = loser.volatility.to_f

        g_j     = g(opp_losers_phi)
        e_j     = expected_score(mu, opp_losers_mu, opp_losers_phi)
        v       = 1.0 / ((g_j**2) * e_j * (1.0 - e_j))
        d_raw   = v * g_j * (loser_score - e_j)

        sigma_prime = new_volatility(sigma, phi, v, d_raw, tau)
        phi_star    = Math.sqrt((phi**2) + (sigma_prime**2))
        new_phi     = 1.0 / Math.sqrt((1.0 / (phi_star**2)) + (1.0 / v))
        new_mu      = mu + ((new_phi**2) * g_j * (loser_score - e_j) * losers_ratio)

        loser.rd         = new_phi * SCALE
        loser.volatility = sigma_prime
        losers_delta << ((mu - new_mu) * SCALE).abs
      end

      [winners_delta, losers_delta]
    end
  end
end

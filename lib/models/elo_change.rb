# frozen_string_literal: true

class EloChange
  include Mongoid::Document

  field :elo, type: Float
  field :delta, type: Float

  belongs_to :user
  embedded_in :match

  def channel_elo
    elo + match.channel.elo
  end

  def new_channel_elo
    channel_elo + delta
  end

  def to_s
    new_elo = new_channel_elo.to_i
    if new_elo.zero?
      nil
    elsif delta.to_i.zero? || new_elo == delta.to_i
      new_elo.positive? ? "+#{new_elo}" : new_elo.to_s
    else
      "#{delta.positive? ? '+' : '-'}#{delta.abs.to_i} → #{new_channel_elo.to_i}"
    end
  end
end

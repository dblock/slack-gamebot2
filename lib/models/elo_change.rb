# frozen_string_literal: true

class EloChange
  include Mongoid::Document

  field :elo, type: Float
  field :delta, type: Float

  belongs_to :user
  embedded_in :match

  def new_elo
    elo + delta
  end

  def new_channel_elo
    new_elo + match.channel.elo
  end

  def to_s
    "#{delta > 0 ? '+' : '-'}#{delta.abs.to_i} → #{new_channel_elo.to_i}"
  end
end

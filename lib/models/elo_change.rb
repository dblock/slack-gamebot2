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
    "#{delta.positive? ? '+' : '-'}#{delta.abs.to_i} → #{new_channel_elo.to_i}"
  end
end

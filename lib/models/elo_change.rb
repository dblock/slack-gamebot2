# frozen_string_literal: true

class EloChange
  include Mongoid::Document

  field :elo, type: Float
  field :delta, type: Float

  belongs_to :user
  embedded_in :match

  def to_s
    "#{elo.to_i} #{delta > 0 ? '+' : '-'}#{delta.abs.to_i}"
  end
end

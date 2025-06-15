class Details
  include Ruby::Enum

  define :ELO, 'elo'
  define :LEADERBOARD, 'leaderboard'

  def self.parse_s(s)
    return unless s

    value = parse(s)
    raise SlackGamebot::Error, "Invalid value: #{s}, possible values are #{Details.values.and}." unless value

    value
  end
end

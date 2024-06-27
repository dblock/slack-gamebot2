module SlackGamebot
  module Commands
    class ChallengeQuestion < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'challenge?' do |channel, challenger, data|
        arguments = data.match['expression'].split.reject(&:blank?) if data.match['expression']
        challenge = ::Challenge.new_from_teammates_and_opponents(challenger, arguments || [])
        match = ::Match.new(team: challenger.channel.team, channel: challenger.channel, winners: challenge.challengers, losers: challenge.challenged, scores: [])
        channel.slack_client.say(channel: data.channel, text: "#{challenge.challengers.map(&:slack_mention).and} challenging #{challenge.challenged.map(&:slack_mention).and} to a match is worth #{match.elo_s} elo.", gif: 'challenge')
        logger.info "CHALLENGE?: #{channel} - #{challenge}"
      end
    end
  end
end

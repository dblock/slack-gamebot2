# frozen_string_literal: true

module SlackGamebot
  module Commands
    class ChallengeQuestion < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'challenge?' do |channel, challenger, data|
        arguments = data.match['expression'].split.reject(&:blank?) if data.match['expression']
        arguments ||= []
        challenge = if arguments.include?('against')
                      ::Challenge.new_from_players_against(channel, arguments)
                    else
                      ::Challenge.new_from_teammates_and_opponents(challenger, arguments)
                    end
        match = ::Match.new(team: channel.team, channel: channel, winners: challenge.challengers, losers: challenge.challenged, scores: [])
        challengers_mention = challenge.challengers.map(&:slack_mention).and
        challenged_mention = challenge.challenged.map(&:slack_mention).and
        challengers_elo = match.winners_elo_s
        challenged_elo = match.losers_elo_s
        elo_text = if challengers_elo == challenged_elo
                     "#{challengers_elo} elo"
                   else
                     "#{challengers_elo} elo for #{challengers_mention} and #{challenged_elo} elo for #{challenged_mention}"
                   end
        channel.slack_client.say(channel: data.channel, text: "#{challengers_mention} challenging #{challenged_mention} to a match is worth #{elo_text}.", gif: 'challenge')
        logger.info "CHALLENGE?: #{channel} - #{challengers_mention} vs #{challenged_mention}"
      end
    end
  end
end

# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Predict < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'predict' do |channel, challenger, data|
        arguments = data.match['expression'].split.reject(&:blank?) if data.match['expression']
        arguments ||= []
        challenge = if arguments.include?('against')
                      ::Challenge.new_from_players_against(channel, arguments)
                    else
                      ::Challenge.new_from_teammates_and_opponents(challenger, arguments)
                    end
        team1_mention = challenge.challengers.map(&:slack_mention).and
        team2_mention = challenge.challenged.map(&:slack_mention).and
        team1_elo = Elo.team_elo(challenge.challengers)
        team2_elo = Elo.team_elo(challenge.challenged)
        win_pct = (1.0 / (1.0 + (10.0**((team2_elo - team1_elo) / 400.0))) * 100).round
        channel.slack_client.say(
          channel: data.channel,
          text: "#{team1_mention} has a #{win_pct}% chance of beating #{team2_mention}.",
          gif: 'predict'
        )
        logger.info "PREDICT: #{channel} - #{team1_mention} vs #{team2_mention}"
      end
    end
  end
end

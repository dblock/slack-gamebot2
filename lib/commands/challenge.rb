module SlackGamebot
  module Commands
    class Challenge < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'challenge' do |channel, challenger, data|
        arguments = data.match['expression'].split.reject(&:blank?) if data.match['expression']
        challenge = ::Challenge.create_from_teammates_and_opponents!(challenger, arguments || [])
        data.team.slack_client.say(channel: data.channel, text: "#{challenge.challengers.map(&:slack_mention).and} challenged #{challenge.challenged.map(&:slack_mention).and} to a match!", gif: 'challenge')
        logger.info "CHALLENGE: #{channel} - #{challenge}"
      end
    end
  end
end

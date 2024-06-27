module SlackGamebot
  module Commands
    class Accept < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'accept' do |channel, user, data|
        challenge = ::Challenge.find_by_user(user)
        challenge ||= ::Challenge.find_open_challenge(channel)

        if challenge
          challenge.accept!(user)
          channel.slack_client.say(channel: data.channel, text: "#{challenge.challenged.map(&:display_name).and} accepted #{challenge.challengers.map(&:display_name).and}'s challenge.", gif: 'game')
          logger.info "ACCEPT: #{user} - #{challenge}"
        else
          channel.slack_client.say(channel: data.channel, text: 'No challenge to accept!')
          logger.info "ACCEPT: #{user} - N/A"
        end
      end
    end
  end
end

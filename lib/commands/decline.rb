module SlackGamebot
  module Commands
    class Decline < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'decline' do |channel, challenger, data|
        challenge = ::Challenge.find_by_user(challenger)
        if challenge
          challenge.decline!(challenger)
          data.team.slack_client.say(channel: data.channel, text: "#{challenge.challenged.map(&:display_name).and} declined #{challenge.challengers.map(&:display_name).and} challenge.", gif: 'no')
          logger.info "DECLINE: #{channel} - #{challenge}"
        else
          data.team.slack_client.say(channel: data.channel, text: 'No challenge to decline!')
          logger.info "DECLINE: #{channel} - #{data.user}, N/A"
        end
      end
    end
  end
end

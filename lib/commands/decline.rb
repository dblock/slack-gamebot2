module SlackGamebot
  module Commands
    class Decline < Base
      include SlackGamebot::Commands::Mixins::Subscription

      subscribed_command 'decline' do |client, data, _match|
        challenger = ::User.find_create_or_update_by_slack_id!(client, data.user)
        challenge = ::Challenge.find_by_user(client.owner, data.channel, challenger)
        if challenge
          challenge.decline!(challenger)
          client.say(channel: data.channel, text: "#{challenge.challenged.map(&:display_name).and} declined #{challenge.challengers.map(&:display_name).and} challenge.", gif: 'no')
          logger.info "DECLINE: #{client.owner} - #{challenge}"
        else
          client.say(channel: data.channel, text: 'No challenge to decline!')
          logger.info "DECLINE: #{client.owner} - #{data.user}, N/A"
        end
      end
    end
  end
end

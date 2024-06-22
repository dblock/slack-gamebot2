module SlackGamebot
  module Commands
    class Taunt < Base
      include SlackGamebot::Commands::Mixins::Subscription

      subscribed_command 'taunt' do |client, data, match|
        taunter = ::User.find_create_or_update_by_slack_id!(client, data.user)
        arguments = match['expression'] ? match['expression'].split.reject(&:blank?) : []
        if arguments.empty?
          client.say(channel: data.channel, text: 'Please provide a user name to taunt.')
        else
          victim = ::User.find_many_by_slack_mention!(client, arguments)
          taunt = "#{victim.map(&:display_name).and} #{victim.count == 1 ? 'sucks' : 'suck'} at this game!"
          client.say(channel: data.channel, text: "#{taunter.user_name} says that #{taunt}")
          logger.info "TAUNT: #{client.owner} - #{taunter.user_name}"
        end
      end
    end
  end
end

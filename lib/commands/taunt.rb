module SlackGamebot
  module Commands
    class Taunt < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'taunt' do |channel, taunter, data|
        arguments = data.match['expression'] ? data.match['expression'].split.reject(&:blank?) : []
        if arguments.empty?
          channel.slack_client.say(channel: data.channel, text: 'Please provide a user name to taunt.')
        else
          victim = channel.find_or_create_many_by_mention!(arguments)
          taunt = "#{victim.map(&:display_name).and} #{victim.count == 1 ? 'sucks' : 'suck'} at this game!"
          channel.slack_client.say(channel: data.channel, text: "#{taunter.user_name} says that #{taunt}")
          logger.info "TAUNT: #{channel} - #{taunter.user_name}"
        end
      end
    end
  end
end

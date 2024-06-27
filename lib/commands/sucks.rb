module SlackGamebot
  module Commands
    class Sucks < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'sucks', 'suck', 'you suck', 'sucks!', 'you suck!' do |channel, user, data|
        if user.losses && user.losses > 5
          channel.slack_client.say(channel: data.channel, text: "No <@#{data.user}>, with #{user.losses} losses, you suck!", gif: 'loser')
        elsif user.rank && user.rank > 3
          channel.slack_client.say(channel: data.channel, text: "No <@#{data.user}>, with a rank of #{user.rank}, you suck!", gif: 'loser')
        else
          channel.slack_client.say(channel: data.channel, text: "No <@#{data.user}>, you suck!", gif: 'rude')
        end
        logger.info "SUCKS: #{channel} - #{data.user}"
      end
    end
  end
end

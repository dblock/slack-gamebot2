module SlackGamebot
  module Commands
    class Register < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'register' do |channel, user, data|
        ts = Time.now.utc
        user.register! if user && !user.registered?
        user.promote! if user && !channel.captains.any?
        message = if user.created_at >= ts
                    "Welcome <@#{data.user}>! You're ready to play."
                  elsif user.updated_at >= ts
                    "Welcome back <@#{data.user}>, I've updated your registration."
                  else
                    "Welcome back <@#{data.user}>, you're already registered."
                  end
        message += " You're also team captain." if user.captain?
        data.team.slack_client.say(channel: data.channel, text: message, gif: 'welcome')
        logger.info "REGISTER: #{channel} - #{data.user}"
        user
      end
    end
  end
end

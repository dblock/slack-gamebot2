module SlackGamebot
  module Commands
    class Hi < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_command 'hi' do |_channel, _user, data|
        data.team.slack_client.say(channel: data.channel, gif: 'hello', text: "Hi <@#{data.user}>!")
        logger.info "HI: #{data.team} - #{data.user}"
      end
    end
  end
end

module SlackGamebot
  module Commands
    class Hi < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_command 'hi' do |channel, _user, data|
        (channel || data.team).slack_client.say(text: "Hi <@#{data.user}>!", channel: data.channel, gif: 'hello')
        logger.info "HI: #{channel || data.team} - #{data.user}"
      end
    end
  end
end

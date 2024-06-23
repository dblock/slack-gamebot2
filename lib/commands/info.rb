module SlackGamebot
  module Commands
    class Info < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_command 'info' do |_channel, _user, data|
        data.team.slack_client.say(channel: data.channel, text: SlackGamebot::INFO)
        logger.info "INFO: #{data.team} - #{data.user}"
      end
    end
  end
end

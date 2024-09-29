# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Info < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_command 'info' do |channel, _user, data|
        (channel || data.team).slack_client.say(channel: data.channel, text: SlackGamebot::INFO)
        logger.info "INFO: #{channel || data.team} - #{data.user}"
      end
    end
  end
end

module SlackGamebot
  module Commands
    class About < SlackRubyBotServer::Events::AppMentions::Mention
      mention 'about'

      def self.call(data)
        return if data.user == data.team.bot_user_id

        data.team.slack_client.say(channel: data.channel, text: SlackGamebot::INFO, gif: 'information')
        logger.info "INFO: #{data.team}, user=#{data.user}"
      end
    end
  end
end

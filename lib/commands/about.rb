module SlackGamebot
  module Commands
    class About < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::Admin

      user_in_channel_or_dm_command 'about' do |channel, _user, data|
        (channel || data.team).slack_client.say(channel: data.channel, text: SlackGamebot::INFO, gif: 'information')
        logger.info "INFO: #{channel || data.team}, user=#{data.user}"
      end
    end
  end
end

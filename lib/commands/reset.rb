module SlackGamebot
  module Commands
    class Reset < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'reset' do |channel, user, data|
        if !user.captain?
          channel.slack_client.say(channel: data.channel, text: "You're not a captain, sorry.", gif: 'sorry')
          logger.info "RESET: #{channel} - #{user.user_name}, failed, not captain"
        elsif !data.match['expression']
          channel.slack_client.say(channel: data.channel, text: "Missing channel, confirm with _reset #{channel.slack_mention}_.", gif: 'help')
          logger.info "RESET: #{channel} - #{user.user_name}, failed, missing channel"
        elsif data.match['expression'] != channel.channel_id && Channel.slack_mention?(data.match['expression']) != channel.channel_id
          channel.slack_client.say(channel: data.channel, text: "Invalid channel, confirm with _reset #{channel.slack_mention}_.", gif: 'help')
          logger.info "RESET: #{channel} - #{user.user_name}, failed, invalid channel '#{data.match['expression']}'"
        else
          ::Season.create!(team: user.team, channel: channel, created_by: user)
          channel.slack_client.say(channel: data.channel, text: 'Welcome to the new season!', gif: 'season')
          logger.info "RESET: #{channel} - #{data.user}"
        end
      end
    end
  end
end

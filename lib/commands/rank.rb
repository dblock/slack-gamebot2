module SlackGamebot
  module Commands
    class Rank < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'rank' do |channel, user, data|
        arguments = data.match['expression'].split.reject(&:blank?) if data.match['expression']
        users = arguments || []
        if arguments&.any?
          users = channel.find_or_create_many_by_mention!(users)
        else
          users << user
        end
        message = User.rank_section(channel, users).map do |user|
          user.rank ? "#{user.rank}. #{user}" : "#{user.user_name}: not ranked"
        end.join("\n")
        channel.slack_client.say(channel: data.channel, text: message)
        logger.info "RANK: #{channel} - #{users.map(&:display_name).and}"
      end
    end
  end
end

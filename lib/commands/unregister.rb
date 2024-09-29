# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Unregister < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'unregister' do |channel, user, data|
        if !data.match['expression'] || data.match['expression'] == 'me'
          user.unregister!
          channel.slack_client.say(channel: data.channel, text: "I've removed #{user.slack_mention} from the leaderboard.", gif: 'removed')
          logger.info "UNREGISTER ME: #{channel} - #{user.slack_mention}"
        elsif data.match['expression']
          names = data.match['expression'].split.reject(&:blank?)
          if user.captain?
            users = channel.find_or_create_many_by_mention!(names)
            users.each(&:unregister!)
            slack_mentions = users.map(&:slack_mention)
            channel.slack_client.say(channel: data.channel, text: "I've removed #{slack_mentions.and} from the leaderboard.", gif: 'find')
            logger.info "UNREGISTER: #{channel} - #{names.and}"
          else
            channel.slack_client.say(channel: data.channel, text: "You're not a captain, sorry.", gif: 'sorry')
            logger.info "UNREGISTER: #{channel} - #{names.and}, failed, not captain"
          end
        end
      end
    end
  end
end

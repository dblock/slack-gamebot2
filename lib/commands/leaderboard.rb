# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Leaderboard < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'leaderboard' do |channel, _user, data|
        max = nil
        reverse = false
        arguments = data.match['expression'].split.reject(&:blank?) if data.match['expression']
        arguments ||= []
        number = arguments.shift
        if number
          if number[0] == '-'
            reverse = true
            number = number[1..]
          end
          max = case number.downcase
                when 'infinity'
                  nil
                else
                  Integer(number)
                end
        end
        message = channel.leaderboard_s(max: max, reverse: reverse)
        if message
          channel.slack_client.say(channel: data.channel, text: message)
        else
          channel.slack_client.say(channel: data.channel, text: "There're no ranked players.", gif: 'empty')
        end
        logger.info "LEADERBOARD #{max || '∞'}: #{channel} - #{data.user}"
      end
    end
  end
end

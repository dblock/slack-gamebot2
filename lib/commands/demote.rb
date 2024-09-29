# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Demote < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'demote' do |channel, user, data|
        if !data.match['expression'] || data.match['expression'] != 'me'
          channel.slack_client.say(channel: data.channel, text: 'You can only demote yourself, try _demote me_.', gif: 'help')
          logger.info "DEMOTE: #{channel} - #{user.user_name}, failed, not me"
        elsif !user.captain?
          channel.slack_client.say(channel: data.channel, text: "You're not a captain, sorry.", gif: 'sorry')
          logger.info "DEMOTE: #{channel} - #{user.user_name}, failed, not captain"
        elsif channel.captains.count == 1
          channel.slack_client.say(channel: data.channel, text: "You cannot demote yourself, you're the last captain. Promote someone else first.", gif: 'sorry')
          logger.info "DEMOTE: #{channel} - #{user.user_name}, failed, last captain"
        else
          user.demote!
          channel.slack_client.say(channel: data.channel, text: "#{user.user_name} is no longer captain.")
          logger.info "DEMOTED: #{channel} - #{user.user_name}"
        end
      end
    end
  end
end

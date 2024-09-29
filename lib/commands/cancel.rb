# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Cancel < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'cancel' do |channel, player, data|
        challenge = ::Challenge.find_by_user(player)
        if challenge
          challenge.cancel!(player)
          if challenge.challengers.include?(player)
            channel.slack_client.say(channel: data.channel, text: "#{challenge.challengers.map(&:display_name).and} canceled a challenge against #{challenge.challenged.map(&:display_name).and}.", gif: 'chicken')
          elsif challenge.challenged.include?(player)
            channel.slack_client.say(channel: data.channel, text: "#{challenge.challenged.map(&:display_name).and} canceled a challenge against #{challenge.challengers.map(&:display_name).and}.", gif: 'chicken')
          else
            channel.slack_client.say(channel: data.channel, text: "#{player.display_name} canceled #{challenge}.", gif: 'chicken')
          end
          logger.info "CANCEL: #{channel} - #{challenge}"
        else
          channel.slack_client.say(channel: data.channel, text: 'No challenge to cancel!')
          logger.info "CANCEL: #{channel} -  #{data.user}, N/A"
        end
      end
    end
  end
end

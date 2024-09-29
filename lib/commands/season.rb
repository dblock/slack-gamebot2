# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Season < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'season' do |channel, _user, data|
        if channel.seasons.count > 0 && channel.challenges.current.none?
          channel.slack_client.say(channel: data.channel, text: 'No matches have been recorded.', gif: 'history')
        elsif channel.challenges.current.any?
          current_season = ::Season.new(team: channel.team, channel: channel)
          channel.slack_client.say(channel: data.channel, text: current_season.to_s)
        else
          channel.slack_client.say(channel: data.channel, text: "There're no seasons.", gif: %w[winter summer fall spring].sample)
        end
        logger.info "SEASON: #{channel} - #{data.user}"
      end
    end
  end
end

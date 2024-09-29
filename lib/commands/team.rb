# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Team < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'team' do |channel, _user, data|
        captains = if channel.captains.count == 1
                     ", captain #{channel.captains.first.display_name}"
                   elsif channel.captains.count > 1
                     ", captains #{channel.captains.map(&:display_name).and}"
                   end
        channel.slack_client.say(channel: data.channel, text: "Team #{channel.team.team_id} #{channel.slack_mention}#{captains}.", gif: 'team')
        logger.info "TEAM: #{channel} - #{data.user}"
      end
    end
  end
end

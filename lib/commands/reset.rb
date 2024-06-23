module SlackGamebot
  module Commands
    class Reset < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_in_channel_command 'reset' do |channel, user, data|
        if !user.captain?
          data.team.slack_client.say(channel: data.channel, text: "You're not a captain, sorry.", gif: 'sorry')
          logger.info "RESET: #{channel} - #{user.user_name}, failed, not captain"
        elsif !data.match['expression']
          data.team.slack_client.say(channel: data.channel, text: "Missing team name or id, confirm with _reset #{user.team.name}_ or _reset #{user.team.team_id}_.", gif: 'help')
          logger.info "RESET: #{channel} - #{user.user_name}, failed, missing team name"
        elsif data.match['expression'] != user.team.name && data.match['expression'] != user.team.team_id
          data.team.slack_client.say(channel: data.channel, text: "Invalid team name or id, confirm with _reset #{user.team.name}_ or _reset #{user.team.team_id}_.", gif: 'help')
          logger.info "RESET: #{channel} - #{user.user_name}, failed, invalid team name '#{data.match['expression']}'"
        else
          ::Season.create!(team: user.team, channel: channel, created_by: user)
          data.team.slack_client.say(channel: data.channel, text: 'Welcome to the new season!', gif: 'season')
          logger.info "RESET: #{channel} - #{data.user}"
        end
      end
    end
  end
end

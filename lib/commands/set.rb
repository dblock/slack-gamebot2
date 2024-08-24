module SlackGamebot
  module Commands
    class Set < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::Admin
      extend SlackGamebot::Commands::SetTeam
      extend SlackGamebot::Commands::SetChannel

      user_in_channel_or_dm_command 'unset' do |channel, user, data|
        if data.match['expression']
          k, v = data.match['expression'].split(/\s+/, 2)
          if channel
            unset_channel channel, data, user, k, v
          else
            unset_team data.team, data, user, k, v
          end
        else
          (channel || data.team).slack_client.say(channel: data.channel, text: 'Missing setting, e.g. _unset api_.', gif: 'help')
          logger.info "UNSET: #{channel || 'DM'} - #{user.user_name}, failed, missing setting"
        end
      end

      user_in_channel_or_dm_command 'set' do |channel, user, data|
        if data.match['expression']
          k, v = data.match['expression'].split(/\s+/, 2)
          if channel
            set_channel channel, data, user, k, v
          else
            set_team data.team, data, user, k, v
          end
        else
          (channel || data.team).slack_client.say(channel: data.channel, text: 'Missing setting, e.g. _set api off_.', gif: 'help')
          logger.info "SET: #{channel || 'DM'} - #{user.user_name}, failed, missing setting"
        end
      end
    end
  end
end

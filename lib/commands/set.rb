module SlackGamebot
  module Commands
    class Set < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::Admin
      extend SlackGamebot::Commands::SetTeam
      extend SlackGamebot::Commands::SetChannel

      class << self
        def parse_int_with_inifinity(v)
          v == 'infinity' ? nil : parse_int(v)
        end

        def parse_int(v)
          Integer(v)
        rescue StandardError
          raise SlackGamebot::Error, "Sorry, #{v} is not a valid number."
        end
      end

      user_in_channel_or_dm_command 'unset' do |channel, user, data|
        k, v = data.match['expression'].split(/\s+/, 2) if data.match['expression']
        if channel
          unset_channel channel, data, user, k, v
        else
          unset_team data.team, data, user, k, v
        end
      end

      user_in_channel_or_dm_command 'set' do |channel, user, data|
        k, v = data.match['expression'].split(/\s+/, 2) if data.match['expression']
        if channel
          set_channel channel, data, user, k, v
        else
          set_team data.team, data, user, k, v
        end
      end
    end
  end
end

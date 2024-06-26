module SlackGamebot
  module Commands
    module Mixins
      module Admin
        extend ActiveSupport::Concern
        include SlackGamebot::Commands::Mixins::Subscribe

        module ClassMethods
          def user_in_channel_or_dm_command(*values, &_block)
            subscribe_command(*values) do |data|
              if data.channel[0] == 'D'
                admin = data.team.find_create_or_updae_admin_by_slack_id!(data.user)
                if admin
                  yield nil, admin, data
                else
                  data.team.slack_client.say(channel: data.channel, text: 'Please run this command in a channel or DM.')
                end
              else
                user = data.team.find_create_or_update_user_in_channel_by_slack_id!(data.channel, data.user)
                channel = user.is_a?(::User) ? user.channel : nil
                if channel
                  yield channel, user, data
                else
                  data.team.slack_client.say(channel: data.channel, text: 'Please run this command in a channel or DM.')
                end
              end
            end
          end
        end
      end
    end
  end
end

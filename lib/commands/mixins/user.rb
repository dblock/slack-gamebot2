module SlackGamebot
  module Commands
    module Mixins
      module User
        extend ActiveSupport::Concern
        include SlackGamebot::Commands::Mixins::Channel

        module ClassMethods
          def user_command(*values, &_block)
            subscribe_command(*values) do |data|
              user = data.team.find_create_or_update_user_in_channel_by_slack_id!(data.channel, data.user)
              yield user.is_a?(::User) ? user.channel : nil, user, data
            end
          end

          def user_in_channel_command(*values, &_block)
            user_command(*values) do |channel, user, data|
              if channel
                yield channel, user, data
              else
                data.team.slack_client.say(channel: data.channel, text: 'Please run this command in a channel.')
              end
            end
          end
        end
      end
    end
  end
end

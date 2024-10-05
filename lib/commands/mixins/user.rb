# frozen_string_literal: true

module SlackGamebot
  module Commands
    module Mixins
      module User
        extend ActiveSupport::Concern
        include SlackGamebot::Commands::Mixins::Subscribe
        include SlackGamebot::Commands::Mixins::Rescue

        module ClassMethods
          def user_command(*values, &_block)
            subscribe_command(*values) do |data|
              user = data.team.find_create_or_update_user_in_channel_by_slack_id!(data.channel, data.user)
              channel = user.is_a?(::User) ? user.channel : nil
              with_rescue(channel || data.team, user, data, &_block)
            end
          end

          def user_in_channel_command(*values, &_block)
            user_command(*values) do |channel, user, data|
              if channel.is_a?(::Channel)
                yield channel, user, data
              else
                data.team.slack_client.say(channel: data.channel, text: [
                  'Invite me to a channel to start a new leaderboard.',
                  "Type `#{data.team.bot_mention} help` for more options."
                ].join("\n"))
              end
            end
          end
        end
      end
    end
  end
end

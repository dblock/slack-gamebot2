# frozen_string_literal: true

module SlackGamebot
  module Commands
    module Mixins
      module DM
        extend ActiveSupport::Concern
        include SlackGamebot::Commands::Mixins::Subscribe

        module ClassMethods
          def dm_command(*values, &_block)
            subscribe_command(*values) do |data|
              team = data.team
              if data && data.channel[0] == 'D'
                admin = team.find_create_or_update_admin_by_slack_id!(data.channel, data.user)
                yield admin, data
              else
                team.slack_client.say(channel: data.channel, text: 'Please run this command in a DM.')
              end
            end
          end
        end
      end
    end
  end
end

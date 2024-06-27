module SlackGamebot
  module Commands
    module Mixins
      module Channel
        extend ActiveSupport::Concern
        include SlackGamebot::Commands::Mixins::Subscribe
        include SlackGamebot::Commands::Mixins::Rescue

        module ClassMethods
          def channel_command(*values, &_block)
            subscribe_command(*values) do |data|
              channel = data.team.find_create_or_update_channel_by_channel_id!(data.channel, data.user)
              with_rescue(channel, nil, data) do |channel, _user, data|
                yield channel, data
              end
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module SlackGamebot
  module Commands
    module Mixins
      module Subscribe
        extend ActiveSupport::Concern
        include SlackGamebot::Commands::Mixins::Rescue

        module ClassMethods
          def subscribe_command(*values, &_block)
            mention(*values) do |data|
              # logger.debug "type=#{data.type}, user=#{data.user}, channel=#{data.channel}, text=#{data.text}"
              next if data.user == data.team.bot_user_id

              if Stripe.api_key && data.team.reload.subscription_expired?
                data.team.slack_client.say channel: data.channel, text: data.team.trial_message
                logger.info "#{data.team}, user=#{data.user}, text=#{data.text}, subscription expired"
              else
                with_rescue(data.team, nil, data) do |_team, _user, data|
                  yield data
                end
              end
            end
          end
        end
      end
    end
  end
end

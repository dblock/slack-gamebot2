module SlackGamebot
  module Commands
    module Mixins
      module Subscribe
        extend ActiveSupport::Concern

        module ClassMethods
          def subscribe_command(*values, &_block)
            mention(*values) do |data|
              next if data.user == data.team.bot_user_id

              if Stripe.api_key && data.team.reload.subscription_expired?
                data.team.slack_client.chat_postMessage channel: data.channel, text: data.team.trial_message
                logger.info "#{data.team}, user=#{data.user}, text=#{data.text}, subscription expired"
              else
                yield data
              end
            rescue Mongoid::Errors::Validations => e
              errors = e.document.errors.messages.transform_values(&:uniq).values.join("\n")
              data.team.slack_client.chat_postMessage channel: data.channel, text: errors
              logger.warn "#{data.team}, user=#{data.user}, text=#{errors}"
            rescue SlackGamebot::Error => e
              data.team.slack_client.chat_postMessage channel: data.channel, text: e.message
              logger.warn "#{data.team}, user=#{data.user}, text=#{e.message}"
            end
          end
        end
      end
    end
  end
end

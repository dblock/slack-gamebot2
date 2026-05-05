# frozen_string_literal: true

module SlackGamebot
  module Commands
    module Mixins
      module Subscribe
        extend ActiveSupport::Concern
        include SlackGamebot::Commands::Mixins::Rescue

        module ClassMethods
          def subscribe_command(*values, &_block)
            # Anchor each keyword to the start of the text (after bot mention is stripped)
            # so that e.g. '@gamebot games undo' doesn't trigger the 'undo' command.
            patterns = values.map { |v| v.is_a?(Regexp) ? v : Regexp.new("\\A#{Regexp.escape(v)}") }
            mention(*patterns) do |data|
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

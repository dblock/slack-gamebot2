# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Unsubscribe < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      user_command 'unsubscribe' do |channel, _user, data|
        team = data.team
        if !team.stripe_customer_id
          data.team.slack_client.say(channel: data.channel, text: "You don't have a paid subscription, all set.")
          logger.info "UNSUBSCRIBE: #{team} - #{data.user} unsubscribe failed, no subscription"
        elsif team.active_stripe_subscription?
          subscription_info = []
          subscription_id = data.match['expression']
          active_subscription = team.active_stripe_subscription
          if active_subscription && active_subscription.id == subscription_id
            active_subscription.delete(at_period_end: true)
            amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
            subscription_info << "Successfully canceled auto-renew for #{active_subscription.plan.name} (#{amount})."
            logger.info "UNSUBSCRIBE: #{team} - #{data.user}, canceled #{subscription_id}"
          elsif subscription_id
            subscription_info << "Sorry, I cannot find a subscription with \"#{subscription_id}\"."
          else
            subscription_info.concat(team.stripe_customer_subscriptions_info(true))
          end
          (channel || team).slack_client.say(channel: data.channel, text: subscription_info.compact.join("\n"))
          logger.info "UNSUBSCRIBE: #{channel || team} - #{data.user}"
        else
          (channel || team).slack_client.say(channel: data.channel, text: 'There are no active subscriptions.', gif: 'sorry')
          logger.info "UNSUBSCRIBE: #{channel || team} - #{data.user}, NONE"
        end
      end
    end
  end
end

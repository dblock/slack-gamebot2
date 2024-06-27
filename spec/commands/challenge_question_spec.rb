require 'spec_helper'

describe SlackGamebot::Commands::ChallengeQuestion do
  include_context 'channel'

  let(:user) { Fabricate(:user, channel: channel, user_name: 'username') }
  let(:opponent) { Fabricate(:user, channel: channel) }

  it 'displays elo at stake for a singles challenge' do
    expect do
      expect(message: "@gamebot challenge? <@#{opponent.user_id}>", user: user, channel: channel).to respond_with_slack_message(
        "#{user.slack_mention} challenging #{opponent.slack_mention} to a match is worth 48 elo."
      )
    end.not_to change(Challenge, :count)
  end

  it 'displays elo at stake for a doubles challenge' do
    opponent2 = Fabricate(:user, channel: channel)
    teammate = Fabricate(:user, channel: channel)
    expect do
      expect(message: "@gamebot challenge? #{opponent.slack_mention} #{opponent2.user_name} with #{teammate.user_name}", user: user, channel: channel).to respond_with_slack_message(
        "#{user.slack_mention} and #{teammate.slack_mention} challenging #{opponent.slack_mention} and #{opponent2.slack_mention} to a match is worth 48 elo."
      )
    end.not_to change(Challenge, :count)
  end

  context 'with unbalanced option enabled' do
    before do
      channel.update_attributes!(unbalanced: true)
    end

    it 'displays elo at stake with different number of opponents' do
      opponent1 = Fabricate(:user, channel: channel)
      opponent2 = Fabricate(:user, channel: channel)
      expect do
        expect(message: "@gamebot challenge? #{opponent1.slack_mention} #{opponent2.slack_mention}", user: user, channel: channel).to respond_with_slack_message(
          "#{user.slack_mention} challenging #{opponent1.slack_mention} and #{opponent2.slack_mention} to a match is worth 24 and 48 elo."
        )
      end.not_to change(Challenge, :count)
    end
  end
end

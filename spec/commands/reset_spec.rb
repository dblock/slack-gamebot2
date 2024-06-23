require 'spec_helper'

describe SlackGamebot::Commands::Reset do
  include_context 'user'

  let(:captain) { Fabricate(:user, channel: channel, captain: true) }

  it 'requires a captain' do
    expect(User).not_to receive(:reset_all!).with(channel)
    expect(message: '@gamebot reset', user: user).to respond_with_slack_message("You're not a captain, sorry.")
  end

  it 'requires a team name' do
    expect(User).not_to receive(:reset_all!).with(channel)
    expect(message: '@gamebot reset', user: captain).to respond_with_slack_message("Missing team name or id, confirm with _reset #{team.name}_ or _reset #{team.team_id}_.")
  end

  it 'requires a matching team name' do
    expect(User).not_to receive(:reset_all!).with(channel)
    expect(message: '@gamebot reset invalid', user: captain).to respond_with_slack_message("Invalid team name or id, confirm with _reset #{team.name}_ or _reset #{team.team_id}_.")
  end

  it 'resets with the correct team name' do
    Fabricate(:match, channel: channel)
    expect(User).to receive(:reset_all!).with(channel).once
    expect(message: "@gamebot reset #{team.name}", user: captain).to respond_with_slack_message('Welcome to the new season!')
  end

  it 'resets with the correct team id' do
    Fabricate(:match, channel: channel)
    expect(User).to receive(:reset_all!).with(channel).once
    expect(message: "@gamebot reset #{team.team_id}", user: captain).to respond_with_slack_message('Welcome to the new season!')
  end

  it 'resets a team that has a period and space in the name' do
    team.update_attributes!(name: 'Pets.com Delivery')
    Fabricate(:match, channel: channel)
    expect(User).to receive(:reset_all!).with(channel).once
    expect(message: "@gamebot reset #{team.name}", user: captain).to respond_with_slack_message('Welcome to the new season!')
  end

  it 'cancels open challenges' do
    proposed_challenge = Fabricate(:challenge, channel: channel, state: ChallengeState::PROPOSED)

    accepted_challenge = Fabricate(:challenge, channel: channel, state: ChallengeState::PROPOSED)
    accepted_challenge.accept!(accepted_challenge.challenged.first)

    expect(message: "@gamebot reset #{team.name}", user: captain).to respond_with_slack_message('Welcome to the new season!')

    expect(proposed_challenge.reload.state).to eq ChallengeState::CANCELED
    expect(accepted_challenge.reload.state).to eq ChallengeState::CANCELED
  end

  it 'resets user stats' do
    Fabricate(:match, channel: channel)
    user = Fabricate(:user, channel: channel, elo: 48, losses: 1, wins: 2, tau: 0.5)
    expect(message: "@gamebot reset #{team.name}", user: captain).to respond_with_slack_message('Welcome to the new season!')
    user.reload
    expect(user.wins).to eq 0
    expect(user.losses).to eq 0
    expect(user.tau).to eq 0
    expect(user.elo).to eq 0
  end

  it 'resets user stats for the right team' do
    Fabricate(:match, channel: channel)
    user1 = Fabricate(:user, channel: channel, elo: 48, losses: 1, wins: 2, tau: 0.5, ties: 3)
    team2 = Fabricate(:team)
    channel2 = Fabricate(:channel, team: team2)
    Fabricate(:match, channel: channel2, team: channel2.team)
    user2 = Fabricate(:user, channel: channel2, elo: 48, losses: 1, wins: 2, tau: 0.5, ties: 3)
    expect(message: "@gamebot reset #{team.name}", user: captain).to respond_with_slack_message('Welcome to the new season!')
    user1.reload
    expect(user1.wins).to eq 0
    expect(user1.losses).to eq 0
    expect(user1.tau).to eq 0
    expect(user1.elo).to eq 0
    expect(user1.ties).to eq 0
    user2.reload
    expect(user2.wins).to eq 2
    expect(user2.losses).to eq 1
    expect(user2.tau).to eq 0.5
    expect(user2.elo).to eq 48
    expect(user2.ties).to eq 3
  end

  it 'cannot be reset unless any games have been played' do
    expect(message: "@gamebot reset #{team.name}", user: captain).to respond_with_slack_message('No matches have been recorded.')
  end

  it 'can be reset with a match lost' do
    Match.lose!(team: team, channel: channel, winners: [Fabricate(:user, channel: channel)], losers: [Fabricate(:user, channel: channel)])
    expect(message: "@gamebot reset #{team.name}", user: captain).to respond_with_slack_message('Welcome to the new season!')
  end
end

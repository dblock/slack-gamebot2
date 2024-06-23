Fabricator(:challenge) do
  channel { Channel.first || Fabricate(:channel) }
  before_create do |instance|
    instance.team ||= instance.channel.team
    instance.challengers << Fabricate(:user, channel: instance.channel) unless instance.challengers.any?
    instance.challenged << Fabricate(:user, channel: instance.channel) unless instance.challenged.any?
    instance.created_by = instance.challengers.first
  end
end

Fabricator(:doubles_challenge, from: :challenge) do
  after_build do |instance|
    instance.challengers = [Fabricate(:user, channel: instance.channel), Fabricate(:user, channel: instance.channel)] unless instance.challengers.any?
    instance.challenged = [Fabricate(:user, channel: instance.channel), Fabricate(:user, channel: instance.channel)] unless instance.challenged.any?
  end
end

Fabricator(:accepted_challenge, from: :challenge) do
  state ChallengeState::ACCEPTED
  before_create do |instance|
    instance.updated_by = instance.challenged.first
  end
end

Fabricator(:declined_challenge, from: :challenge) do
  state ChallengeState::DECLINED
  before_create do |instance|
    instance.updated_by = instance.challenged.first
  end
end

Fabricator(:canceled_challenge, from: :challenge) do
  state ChallengeState::CANCELED
  before_create do |instance|
    instance.updated_by = instance.challengers.first
  end
end

Fabricator(:played_challenge, from: :challenge) do
  state ChallengeState::PLAYED
  before_create do |instance|
    instance.updated_by = instance.challenged.first
  end
end

RSpec.shared_context 'subscribed team' do
  let!(:team) { Fabricate(:team, subscribed: true) }
end

RSpec.shared_context 'team' do
  let!(:team) { Fabricate(:team) }
end

RSpec.shared_context 'channel' do
  include_context 'subscribed team'

  let!(:channel) { Fabricate(:channel, channel_id: 'channel', team: team) }

  before do
    allow_any_instance_of(Slack::Web::Client).to receive(:users_info)
  end
end

RSpec.shared_context 'user' do
  include_context 'channel'

  let!(:user) { Fabricate(:user, channel: channel, user_name: 'username') }
end

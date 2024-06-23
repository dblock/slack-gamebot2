Fabricator(:user) do
  user_id { Fabricate.sequence(:user_id) { |i| "U#{i}" } }
  user_name { Faker::Internet.user_name }
  channel { Channel.first || Fabricate(:channel) }
  before_create do |instance|
    instance.team ||= instance.channel.team
  end
end

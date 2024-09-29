# frozen_string_literal: true

Fabricator(:season) do
  channel { Channel.first || Fabricate(:channel) }
  before_create do |instance|
    instance.team ||= instance.channel.team
    Fabricate(:match, channel: channel) if Challenge.current.none?
  end
end

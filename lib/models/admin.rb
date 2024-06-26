class Admin
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :user_name, type: String
  field :is_admin, type: Boolean, default: false
  field :is_owner, type: Boolean, default: false

  belongs_to :team, index: true

  validates_presence_of :team

  index({ user_id: 1, team_id: 1 }, unique: true)
  index(user_name: 1, team_id: 1)

  def slack_mention
    "<@#{user_id}>"
  end

  def team_admin?
    activated_user? || is_admin? || is_owner?
  end

  def activated_user?
    team.activated_user_id && team.activated_user_id == user_id
  end
end

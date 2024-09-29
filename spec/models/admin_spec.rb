# frozen_string_literal: true

require 'spec_helper'

describe Admin do
  let(:team) { Fabricate(:team, activated_user_id: 'activated_user_id') }

  context 'nobody' do
    let(:admin) { Fabricate(:admin, team: team, is_owner: false, is_admin: false) }

    it 'team_admin?' do
      expect(admin.team_admin?).to be false
    end
  end

  context 'owner' do
    let(:admin) { Fabricate(:admin, team: team, is_owner: true, is_admin: false) }

    it 'team_admin?' do
      expect(admin.team_admin?).to be true
    end
  end

  context 'admin' do
    let(:admin) { Fabricate(:admin, team: team, is_owner: false, is_admin: true) }

    it 'team_admin?' do
      expect(admin.team_admin?).to be true
    end
  end

  context 'team activator' do
    let(:admin) { Fabricate(:admin, team: team, is_owner: false, is_admin: false, user_id: team.activated_user_id) }

    it 'team_admin?' do
      expect(admin.team_admin?).to be true
    end
  end
end

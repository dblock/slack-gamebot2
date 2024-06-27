require 'spec_helper'

describe SlackGamebot::Commands::Set do
  context 'channel' do
    include_context 'user'

    let(:captain) { Fabricate(:user, channel: channel, captain: true) }

    context 'captain' do
      before do
        user.update_attributes!(captain: true)
      end

      it 'gives help' do
        expect(message: '@gamebot set', user: captain).to respond_with_slack_message(
          'Missing setting, e.g. _set api off_.'
        )
      end

      context 'gifs' do
        it 'shows current value of GIFs on' do
          expect(message: '@gamebot set gifs', user: captain).to respond_with_slack_message(
            "GIFs for #{channel.slack_mention} are on!"
          )
        end

        it 'shows current value of GIFs off' do
          channel.update_attributes!(gifs: false)
          expect(message: '@gamebot set gifs', user: captain).to respond_with_slack_message(
            "GIFs for #{channel.slack_mention} are off."
          )
        end

        it 'shows current value of GIFs on' do
          expect(message: '@gamebot set gifs', user: captain).to respond_with_slack_message(
            "GIFs for #{channel.slack_mention} are on!"
          )
        end

        it 'shows current value of GIFs off' do
          channel.update_attributes!(gifs: false)
          expect(message: '@gamebot set gifs', user: captain).to respond_with_slack_message(
            "GIFs for #{channel.slack_mention} are off."
          )
        end

        it 'enables GIFs' do
          channel.update_attributes!(gifs: false)
          expect(message: '@gamebot set gifs on', user: captain).to respond_with_slack_message(
            "GIFs for #{channel.slack_mention} are on!"
          )
          expect(channel.reload.gifs).to be true
        end

        it 'disables GIFs with set' do
          channel.update_attributes!(gifs: true)
          expect(message: '@gamebot set gifs off', user: captain).to respond_with_slack_message(
            "GIFs for #{channel.slack_mention} are off."
          )
          expect(channel.reload.gifs).to be false
        end

        it 'disables GIFs with unset' do
          channel.update_attributes!(gifs: true)
          expect(message: '@gamebot unset gifs', user: captain).to respond_with_slack_message(
            "GIFs for #{channel.slack_mention} are off."
          )
          expect(channel.reload.gifs).to be false
        end
      end

      context 'unbalanced' do
        it 'shows current value of unbalanced off' do
          expect(message: '@gamebot set unbalanced', user: captain).to respond_with_slack_message(
            "Unbalanced challenges for #{channel.slack_mention} are off."
          )
        end

        it 'shows current value of unbalanced off' do
          channel.update_attributes!(unbalanced: false)
          expect(message: '@gamebot set unbalanced', user: captain).to respond_with_slack_message(
            "Unbalanced challenges for #{channel.slack_mention} are off."
          )
        end

        it 'shows current value of unbalanced off' do
          expect(message: '@gamebot set unbalanced', user: captain).to respond_with_slack_message(
            "Unbalanced challenges for #{channel.slack_mention} are off."
          )
        end

        it 'shows current value of unbalanced off' do
          channel.update_attributes!(unbalanced: false)
          expect(message: '@gamebot set unbalanced', user: captain).to respond_with_slack_message(
            "Unbalanced challenges for #{channel.slack_mention} are off."
          )
        end

        it 'enables unbalanced' do
          channel.update_attributes!(unbalanced: false)
          expect(message: '@gamebot set unbalanced on', user: captain).to respond_with_slack_message(
            "Unbalanced challenges for #{channel.slack_mention} are on!"
          )
          expect(channel.reload.unbalanced).to be true
        end

        it 'disables unbalanced with set' do
          channel.update_attributes!(unbalanced: true)
          expect(message: '@gamebot set unbalanced off', user: captain).to respond_with_slack_message(
            "Unbalanced challenges for #{channel.slack_mention} are off."
          )
          expect(channel.reload.unbalanced).to be false
        end

        it 'disables unbalanced with unset' do
          channel.update_attributes!(unbalanced: true)
          expect(message: '@gamebot unset unbalanced', user: captain).to respond_with_slack_message(
            "Unbalanced challenges for #{channel.slack_mention} are off."
          )
          expect(channel.reload.unbalanced).to be false
        end
      end

      context 'api' do
        it 'shows current value of API on' do
          team.update_attributes!(api: true)
          channel.update_attributes!(api: true)
          expect(message: '@gamebot set api', user: captain).to respond_with_slack_message(
            "API for #{channel.slack_mention} is on!\nDM the bot for an API token to pass as an `X-Api-Token` header to #{channel.api_url}."
          )
        end

        it 'shows current value of API on' do
          team.update_attributes!(api: false)
          channel.update_attributes!(api: true)
          expect(message: '@gamebot set api', user: captain).to respond_with_slack_message(
            "API for team #{team.team_id} is off. DM the bot to turn it on."
          )
        end

        it 'shows current value of API off' do
          channel.update_attributes!(api: false)
          expect(message: '@gamebot set api', user: captain).to respond_with_slack_message(
            "API for #{channel.slack_mention} is off."
          )
        end

        it 'shows current value of API on' do
          channel.update_attributes!(api: true)
          expect(message: '@gamebot set api', user: captain).to respond_with_slack_message(
            "API for #{channel.slack_mention} is on!\nDM the bot for an API token to pass as an `X-Api-Token` header to #{channel.api_url}."
          )
        end

        it 'shows current value of API off' do
          channel.update_attributes!(api: false)
          expect(message: '@gamebot set api', user: captain).to respond_with_slack_message(
            "API for #{channel.slack_mention} is off."
          )
        end

        it 'enables API' do
          expect(message: '@gamebot set api on', user: captain).to respond_with_slack_message(
            "API for #{channel.slack_mention} is on!\nDM the bot for an API token to pass as an `X-Api-Token` header to #{channel.api_url}."
          )
          expect(channel.reload.api).to be true
        end

        it 'disables API with set' do
          channel.update_attributes!(api: true)
          expect(message: '@gamebot set api off', user: captain).to respond_with_slack_message(
            "API for #{channel.slack_mention} is off."
          )
          expect(channel.reload.api).to be false
        end

        it 'disables API with unset' do
          channel.update_attributes!(api: true)
          expect(message: '@gamebot unset api', user: captain).to respond_with_slack_message(
            "API for #{channel.slack_mention} is off."
          )
          expect(channel.reload.api).to be false
        end

        context 'with API_URL' do
          before do
            ENV['API_URL'] = 'http://local.api'
          end

          after do
            ENV.delete 'API_URL'
          end

          it 'shows current value of API on with API URL' do
            channel.update_attributes!(api: true)
            expect(message: '@gamebot set api', user: captain).to respond_with_slack_message(
              "API for #{channel.slack_mention} is on!\nDM the bot for an API token to pass as an `X-Api-Token` header to http://local.api/channels/#{channel.id}."
            )
          end

          it 'shows current value of API off without API URL' do
            channel.update_attributes!(api: false)
            expect(message: '@gamebot set api', user: captain).to respond_with_slack_message(
              "API for #{channel.slack_mention} is off."
            )
          end
        end
      end

      context 'aliases' do
        context 'with aliases' do
          before do
            channel.update_attributes!(aliases: %w[foo bar])
          end

          it 'shows current value of aliases' do
            expect(message: '@gamebot set aliases', user: captain).to respond_with_slack_message(
              "Bot aliases for #{channel.slack_mention} are `foo` and `bar`."
            )
          end
        end

        context 'with aliases' do
          before do
            channel.update_attributes!(aliases: %w[foo bar])
          end

          it 'shows current value of aliases' do
            expect(message: '@gamebot set aliases', user: captain).to respond_with_slack_message(
              "Bot aliases for #{channel.slack_mention} are `foo` and `bar`."
            )
          end

          it 'sets aliases' do
            expect(message: '@gamebot set aliases foo bar baz', user: captain).to respond_with_slack_message(
              "Bot aliases for #{channel.slack_mention} are `foo`, `bar` and `baz`."
            )
            expect(channel.reload.aliases).to eq %w[foo bar baz]
          end

          it 'sets comma-separated aliases' do
            expect(message: '@gamebot set aliases foo,bar', user: captain).to respond_with_slack_message(
              "Bot aliases for #{channel.slack_mention} are `foo` and `bar`."
            )
            expect(channel.reload.aliases).to eq %w[foo bar]
          end

          it 'sets comma-separated aliases with extra spaces' do
            expect(message: '@gamebot set aliases   foo,    bar', user: captain).to respond_with_slack_message(
              "Bot aliases for #{channel.slack_mention} are `foo` and `bar`."
            )
            expect(channel.reload.aliases).to eq %w[foo bar]
          end

          it 'sets emoji aliases' do
            expect(message: '@gamebot set aliases pp :pong:', user: captain).to respond_with_slack_message(
              "Bot aliases for #{channel.slack_mention} are `pp` and `:pong:`."
            )
            expect(channel.reload.aliases).to eq ['pp', ':pong:']
          end

          it 'removes aliases' do
            expect(message: '@gamebot unset aliases', user: captain).to respond_with_slack_message(
              "#{channel.slack_mention} no longer has bot aliases."
            )
            expect(channel.reload.aliases).to be_empty
          end
        end

        context 'without aliases' do
          before do
            channel.update_attributes!(aliases: [])
          end

          it 'shows no aliases' do
            expect(message: '@gamebot set aliases', user: captain).to respond_with_slack_message(
              "#{channel.slack_mention} does not have any bot aliases."
            )
          end
        end
      end

      context 'elo' do
        context 'with a non-default base elo' do
          before do
            channel.update_attributes!(elo: 1000)
          end

          it 'shows current value of elo' do
            expect(message: '@gamebot set elo', user: captain).to respond_with_slack_message(
              "Base elo for #{channel.slack_mention} is 1000."
            )
          end

          it 'sets elo' do
            expect(message: '@gamebot set elo 200', user: captain).to respond_with_slack_message(
              "Base elo for #{channel.slack_mention} is 200."
            )
            expect(channel.reload.elo).to eq 200
          end

          it 'handles errors' do
            expect(message: '@gamebot set elo invalid', user: captain).to respond_with_slack_message(
              'Sorry, invalid is not a valid number.'
            )
            expect(channel.reload.elo).to eq 1000
          end

          it 'resets elo with set' do
            expect(message: '@gamebot set elo 0', user: captain).to respond_with_slack_message(
              "Base elo for #{channel.slack_mention} is 0."
            )
            expect(channel.reload.elo).to eq 0
          end

          it 'resets elo with unset' do
            expect(message: '@gamebot unset elo', user: captain).to respond_with_slack_message(
              "Base elo for #{channel.slack_mention} has been unset."
            )
            expect(channel.reload.elo).to eq 0
          end
        end
      end

      context 'leaderboard max' do
        context 'with a non-default leaderboard max' do
          before do
            channel.update_attributes!(leaderboard_max: 5)
          end

          it 'shows current value of leaderboard max' do
            expect(message: '@gamebot set leaderboard max', user: captain).to respond_with_slack_message(
              "Leaderboard max for #{channel.slack_mention} is 5."
            )
          end

          it 'sets leaderboard max' do
            expect(message: '@gamebot set leaderboard max 12', user: captain).to respond_with_slack_message(
              "Leaderboard max for #{channel.slack_mention} is 12."
            )
            expect(channel.reload.leaderboard_max).to eq 12
          end

          it 'sets leaderboard max to a negative number' do
            expect(message: '@gamebot set leaderboard max -12', user: captain).to respond_with_slack_message(
              "Leaderboard max for #{channel.slack_mention} is -12."
            )
            expect(channel.reload.leaderboard_max).to eq(-12)
          end

          it 'handles errors' do
            expect(message: '@gamebot set leaderboard max invalid', user: captain).to respond_with_slack_message(
              'Sorry, invalid is not a valid number.'
            )
            expect(channel.reload.leaderboard_max).to eq 5
          end

          it 'resets leaderboard max with set 0' do
            expect(message: '@gamebot set leaderboard max 0', user: captain).to respond_with_slack_message(
              "Leaderboard max for #{channel.slack_mention} is not set."
            )
            expect(channel.reload.leaderboard_max).to be_nil
          end

          it 'resets leaderboard max with set infinity' do
            expect(message: '@gamebot set leaderboard max infinity', user: captain).to respond_with_slack_message(
              "Leaderboard max for #{channel.slack_mention} is not set."
            )
            expect(channel.reload.leaderboard_max).to be_nil
          end

          it 'resets leaderboard max with unset' do
            expect(message: '@gamebot unset leaderboard max', user: captain).to respond_with_slack_message(
              "Leaderboard max for #{channel.slack_mention} has been unset."
            )
            expect(channel.reload.leaderboard_max).to be_nil
          end
        end
      end

      context 'invalid' do
        it 'errors set' do
          expect(message: '@gamebot set invalid on', user: captain).to respond_with_slack_message(
            'Invalid setting invalid, you can _set gifs on|off_, _set unbalanced on|off_, _api on|off_, _leaderboard max_, _elo_, _nickname_ and _aliases_.'
          )
        end

        it 'errors unset' do
          expect(message: '@gamebot unset invalid', user: captain).to respond_with_slack_message(
            'Invalid setting invalid, you can _unset gifs_, _api_, _leaderboard max_, _elo_, _nickname_ and _aliases_.'
          )
        end
      end
    end

    context 'not captain' do
      context 'api' do
        it 'cannot set api' do
          expect(message: '@gamebot set api true', user: user).to respond_with_slack_message(
            "You're not a captain, sorry."
          )
        end

        it 'can see api' do
          expect(message: '@gamebot set api', user: user).to respond_with_slack_message(
            "API for #{channel.slack_mention} is on!\nDM the bot for an API token to pass as an `X-Api-Token` header to #{channel.api_url}."
          )
        end
      end

      context 'gifs' do
        it 'cannot set GIFs' do
          expect(message: '@gamebot set gifs true', user: user).to respond_with_slack_message(
            "You're not a captain, sorry."
          )
        end

        it 'can see GIFs value' do
          expect(message: '@gamebot set gifs', user: user).to respond_with_slack_message(
            "GIFs for #{channel.slack_mention} are on!"
          )
        end
      end

      context 'aliases' do
        it 'cannot set aliases' do
          expect(message: '@gamebot set aliases foo bar', user: user).to respond_with_slack_message(
            "You're not a captain, sorry."
          )
        end

        it 'can see aliases' do
          expect(message: '@gamebot set aliases', user: user).to respond_with_slack_message(
            "Bot aliases for #{channel.slack_mention} are `gamebot`, `pongbot` and `pp`."
          )
        end
      end

      context 'elo' do
        it 'cannot set elo' do
          expect(message: '@gamebot set elo 1000', user: user).to respond_with_slack_message(
            "You're not a captain, sorry."
          )
        end

        it 'can see elo' do
          expect(message: '@gamebot set elo', user: user).to respond_with_slack_message(
            "Base elo for #{channel.slack_mention} is 0."
          )
        end
      end

      context 'leaderboard max' do
        it 'cannot set leaderboard max' do
          expect(message: '@gamebot set leaderboard max 3', user: user).to respond_with_slack_message(
            "You're not a captain, sorry."
          )
        end

        it 'can see leaderboard max' do
          expect(message: '@gamebot set leaderboard max', user: user).to respond_with_slack_message(
            "Leaderboard max for #{channel.slack_mention} is not set."
          )
        end
      end
    end

    context 'nickname' do
      let(:user) { Fabricate(:user, channel: channel, user_name: 'username') }

      context 'with no nickname' do
        it 'shows that the user has no nickname' do
          expect(message: '@gamebot set nickname', user: user).to respond_with_slack_message(
            "You don't have a nickname set, #{user.user_name}."
          )
        end
      end

      context 'without a nickname set' do
        it 'sets nickname' do
          expect(message: '@gamebot set nickname john doe', user: user).to respond_with_slack_message(
            "Your nickname is now *john doe*, #{user.slack_mention}."
          )
          expect(user.reload.nickname).to eq 'john doe'
        end

        it 'does not unset nickname' do
          expect(message: '@gamebot unset nickname', user: user).to respond_with_slack_message(
            "You don't have a nickname set, #{user.slack_mention}."
          )
          expect(user.reload.nickname).to be_nil
        end

        it 'sets emoji nickname' do
          expect(message: '@gamebot set nickname :dancer:', user: user).to respond_with_slack_message(
            "Your nickname is now *:dancer:*, #{user.slack_mention}."
          )
          expect(user.reload.nickname).to eq ':dancer:'
        end
      end

      context 'with a nickname set' do
        before do
          user.update_attributes!(nickname: 'bob')
        end

        it 'shows current value of nickname' do
          expect(message: '@gamebot set nickname', user: user).to respond_with_slack_message(
            "Your nickname is *bob*, #{user.slack_mention}."
          )
        end

        it 'sets nickname' do
          expect(message: '@gamebot set nickname john doe', user: user).to respond_with_slack_message(
            "Your nickname is now *john doe*, #{user.slack_mention}."
          )
          expect(user.reload.nickname).to eq 'john doe'
        end

        it 'unsets nickname' do
          expect(message: '@gamebot unset nickname', user: user).to respond_with_slack_message(
            "You don't have a nickname set anymore, #{user.slack_mention}."
          )
          expect(user.reload.nickname).to be_nil
        end

        it 'cannot set nickname unless captain' do
          expect(message: "@gamebot set nickname #{captain.slack_mention} :dancer:", user: user).to respond_with_slack_message(
            "You're not a captain, sorry."
          )
        end

        it 'sets nickname for another user' do
          captain = Fabricate(:user, channel: channel, captain: true)
          expect(message: "@gamebot set nickname #{user.slack_mention} john doe", user: captain).to respond_with_slack_message(
            "Your nickname is now *john doe*, #{user.slack_mention}."
          )
          expect(user.reload.nickname).to eq 'john doe'
        end

        it 'unsets nickname for another user' do
          user.update_attributes!(nickname: 'bob')
          expect(message: "@gamebot unset nickname #{user.slack_mention}", user: captain).to respond_with_slack_message(
            "You don't have a nickname set anymore, #{user.slack_mention}."
          )
          expect(user.reload.nickname).to be_nil
        end
      end
    end
  end

  context 'DM' do
    include_context 'dm'

    let(:admin) { Fabricate(:admin, is_owner: true, is_admin: true) }
    let(:user) { Fabricate(:admin, is_owner: false, is_admin: false, user_id: 'some_user_id') }

    context 'invalid' do
      it 'errors set' do
        expect(message: '@gamebot set invalid on', user: user.user_id, channel: 'DM').to respond_with_slack_message(
          'Invalid setting invalid, you can _set api on|off_, and _set token xyz_.'
        )
      end

      it 'errors unset' do
        expect(message: '@gamebot unset invalid', user: user.user_id, channel: 'DM').to respond_with_slack_message(
          'Invalid setting invalid, you can _unset api_ and _token_.'
        )
      end
    end

    context 'not captain' do
      context 'api' do
        it 'cannot set api' do
          expect(message: '@gamebot set api true', user: user.user_id, channel: 'DM').to respond_with_slack_message(
            "You're not a team admin, sorry."
          )
        end

        it 'can see api' do
          expect(message: '@gamebot set api', user: user.user_id, channel: 'DM').to respond_with_slack_message(
            "API for team #{team.team_id} is on, set an API token with _set token xyz_."
          )
        end
      end

      context 'token' do
        it 'cannot set token' do
          expect(message: '@gamebot set token xyz', user: user.user_id, channel: 'DM').to respond_with_slack_message(
            "You're not a team admin, sorry."
          )
        end

        it 'cannot see api token' do
          expect(message: '@gamebot set token', user: user.user_id, channel: 'DM').to respond_with_slack_message(
            "You're not a team admin, sorry."
          )
        end
      end
    end

    context 'api' do
      it 'shows current value of API on' do
        team.update_attributes!(api: true)
        expect(message: '@gamebot set api', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is on, set an API token with _set token xyz_."
        )
      end

      it 'shows current value of API on with token' do
        team.update_attributes!(api: true, api_token: 'token')
        expect(message: '@gamebot set api', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is on, and the API token is set to `token`.\nPass it in with an `X-Api-Token` header to #{team.api_url}."
        )
      end

      it 'shows current value of API off' do
        team.update_attributes!(api: false)
        expect(message: '@gamebot set api', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is off."
        )
      end

      it 'enables API' do
        expect(message: '@gamebot set api on', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is on, set an API token with _set token xyz_."
        )
        expect(team.reload.api).to be true
      end

      it 'disables API with set' do
        team.update_attributes!(api: true)
        expect(message: '@gamebot set api off', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is off."
        )
        expect(team.reload.api).to be false
      end

      it 'disables API with unset' do
        team.update_attributes!(api: true)
        expect(message: '@gamebot unset api', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is off."
        )
        expect(team.reload.api).to be false
      end
    end

    context 'token' do
      it 'shows current value of API token' do
        team.update_attributes!(api: true, api_token: 'token')
        expect(message: '@gamebot set token', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is on, and the API token is `#{team.api_token}`.\nPass it in with an `X-Api-Token` header to #{team.api_url}."
        )
      end

      it 'shows when API token is not set' do
        team.update_attributes!(api: true, api_token: nil)
        expect(message: '@gamebot set token', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is on, set an API token with _set token xyz_."
        )
      end

      it 'sets API token with set' do
        expect(message: '@gamebot set token xyz', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API for team #{team.team_id} is on, and the API token is `xyz`.\nPass it in with an `X-Api-Token` header to #{team.api_url}."
        )
        expect(team.reload.api_token).to eq 'xyz'
      end

      it 'removes API token with unset' do
        team.update_attributes!(api_token: 'xyz')
        expect(message: '@gamebot unset token', user: admin.user_id, channel: 'DM').to respond_with_slack_message(
          "API token for team #{team.team_id} is not set."
        )
        expect(team.reload.api_token).to be_nil
      end
    end
  end
end

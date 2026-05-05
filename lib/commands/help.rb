# frozen_string_literal: true

module SlackGamebot
  module Commands
    class Help < SlackRubyBotServer::Events::AppMentions::Mention
      include SlackGamebot::Commands::Mixins::User

      HELP = <<~EOS
        I am your friendly Gamebot, here to help.

        ```
        Games
        -----
        challenge <opponent> ... [with <teammate> ...]: challenge opponent(s) to a game
        challenge @here|@channel: challenge anyone to a game
        challenge? <opponent> ... [with <teammate> ...]: show elo at stake
        challenge? <player> ... against <player> ...: show elo at stake between other players
        predict <opponent> ... [with <teammate> ...]: predict win probability
        predict <player> ... against <player> ...: predict between other players
        challenges: show pending challenges
        accept: accept a challenge
        decline: decline a previous challenge
        cancel: cancel a previous challenge
        lost [to <opponent>] [score, ...]: record your loss
        won [against <opponent>] [score, ...]: record your win
        resigned [to <opponent>]: record a resignation
        draw [to <opponent>] [score, ...]: record a tie
        undo: undo the last match recorded in the last hour
        taunt <opponent> [<opponent> ...]: taunt players
        rank [<player> ...]: rank a player or a list of players
        matches [number|infinity]: show this season's matches
        games [<player> ...]: show how many games each player has played
        register: re-register yourself as a player
        unregister: unregister yourself, removes you from leaderboards and challenges

        Stats
        -----
        leaderboard [number|infinity]: show the leaderboard, e.g. leaderboard 10
        season: show current season
        seasons: show all seasons

        Settings
        --------
        set nickname [name], unset nickname: set/unset your nickname displayed in leaderboards
        set leaderboard max [number|none], unset leaderboard max: set/unset leaderboard max
        set expire [m|h|never], unset expire: set/unset challenge expiry, min 15m, default is 8h
        set remind [m|h|never], unset remind: set/unset reminder for unrecorded accepted challenges, min 15m, default is 4h
        set max challenges [number|none], unset max challenges: set/remove limit on simultaneous accepted challenges
        set max challenges per day [number|none], unset max challenges per day: set/remove daily challenge limit for the channel
        set max challenges per user [number|none], unset max challenges per user: set/remove limit on challenges issued per user per day
        set max games per user [number|none], unset max games per user: set/remove limit on games a user can participate in per day
        set timezone [name], unset timezone: set/reset timezone used for daily limits, default is Eastern Time (US & Canada)
        set gifs [on|off], unset gifs: enable/disable animated GIFs, default is on
        set aliases [<alias> ...], unset aliases: set/unset additional bot aliases in public channels
        set elo [number], unset elo: set/unset base elo for the team
        set elo algorithm [adaptive|standard|glicko|glicko2]: set elo algorithm, only at start of season, default is adaptive
        set elo decay [number]: set adaptive algorithm decay factor (0-1), default is 0.94
        set elo k [number]: set standard algorithm K-factor, default is 32
        set elo glicko2 tau [number]: set glicko2 system constant τ, default is 0.5
        set api [on|off], unset api: enable/disable team data in the public API, default is off
        set token [token], unset token: set/unset API token
        set won [on|off], unset won: enable/disable the won command, default is on
        set unbalanced [on|off], unset unbalanced: allow/disallow matches between different numbers of players, default is off
        set details [elo,leaderboard|none]: show match elo details, auto-post a leaderboard in a thread

        Captains
        --------
        promote <player>: promote a user to captain
        demote me: demote you from captain
        set nickname <player> [name], unset nickname <player>: set/unset someone's nickname
        reset <channel>: reset all stats, start a new season
        unregister <player>: remove a player from the leaderboard

        Other
        -----
        hi: be nice, say hi to your bot
        team: show your team's info and captains
        about: show bot info
        channels: show all channels with current season stats (DM only)
        subscription: show subscription info (captains also see payment data)
        unsubscribe: do not auto-renew subscription
        help: get this helpful message
        info: bot credits
        sucks: express some frustration
        ```
      EOS

      user_command 'help' do |channel, _user, data|
        team = data.team
        (channel || team).slack_client.say(channel: data.channel, text: [
          HELP,
          team.reload.subscribed? ? nil : team.trial_message
        ].compact.join("\n"), gif: 'help')
        logger.info "HELP: #{team} - #{data.user}"
      end
    end
  end
end

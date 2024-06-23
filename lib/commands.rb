require_relative 'commands/mixins'
require_relative 'commands/hi'
require_relative 'commands/about'
require_relative 'commands/accept'
require_relative 'commands/cancel'
require_relative 'commands/challenge'
require_relative 'commands/challenge_question'
require_relative 'commands/challenges'
require_relative 'commands/decline'
require_relative 'commands/help'
require_relative 'commands/info'
require_relative 'commands/rank'
require_relative 'commands/leaderboard'
require_relative 'commands/lost'
require_relative 'commands/resigned'
require_relative 'commands/draw'
require_relative 'commands/register'
require_relative 'commands/unregister'
require_relative 'commands/reset'
require_relative 'commands/seasons'
require_relative 'commands/season'
require_relative 'commands/matches'
require_relative 'commands/promote'
require_relative 'commands/demote'
require_relative 'commands/taunt'
require_relative 'commands/team'
require_relative 'commands/set'
require_relative 'commands/sucks'
require_relative 'commands/subscription'
require_relative 'commands/unsubscribe'

SlackRubyBotServer::Events::AppMentions.configure do |config|
  config.handlers = [
    SlackGamebot::Commands::Hi,
    SlackGamebot::Commands::Help,
    SlackGamebot::Commands::Info,
    SlackGamebot::Commands::About,
    SlackGamebot::Commands::Subscription,
    SlackGamebot::Commands::Unsubscribe,
    SlackGamebot::Commands::Reset,
    SlackGamebot::Commands::Set,
    SlackGamebot::Commands::Promote,
    SlackGamebot::Commands::Demote,
    SlackGamebot::Commands::Accept,
    SlackGamebot::Commands::Decline,
    SlackGamebot::Commands::Cancel,
    SlackGamebot::Commands::Challenge,
    SlackGamebot::Commands::ChallengeQuestion,
    SlackGamebot::Commands::Challenges,
    SlackGamebot::Commands::Rank,
    SlackGamebot::Commands::Leaderboard,
    SlackGamebot::Commands::Lost,
    SlackGamebot::Commands::Resigned,
    SlackGamebot::Commands::Draw,
    SlackGamebot::Commands::Unregister,
    SlackGamebot::Commands::Register,
    SlackGamebot::Commands::Seasons,
    SlackGamebot::Commands::Season,
    SlackGamebot::Commands::Matches,
    SlackGamebot::Commands::Taunt,
    SlackGamebot::Commands::Team,
    SlackGamebot::Commands::Sucks
  ]
end

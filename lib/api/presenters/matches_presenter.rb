# frozen_string_literal: true

module SlackGamebot
  module Api
    module Presenters
      module MatchesPresenter
        include Roar::JSON::HAL
        include Roar::Hypermedia
        include Grape::Roar::Representer
        include Api::Presenters::PaginatedPresenter

        collection :results, extend: MatchPresenter, as: :matches, embedded: true
      end
    end
  end
end

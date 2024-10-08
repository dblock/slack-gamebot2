# frozen_string_literal: true

def logger
  @logger ||= begin
    $stdout.sync = true
    Logger.new($stdout)
  end
end

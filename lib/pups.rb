require "logger"
require "yaml"

require "pups/version"
require "pups/config"
require "pups/process"

module Pups
  def self.log
    # at the moment docker likes this
    @logger ||= Logger.new(STDERR)
  end

  def self.log=(logger)
    @logger = logger
  end
end

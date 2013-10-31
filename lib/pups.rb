require "logger"
require "yaml"

require "pups/version"
require "pups/config"
require "pups/command"
require "pups/exec_command"
require "pups/merge_command"

require "pups/runit/base"
require "pups/runit/nginx"
require "pups/runit/postgres"
require "pups/runit/sidekiq"
require "pups/runit/sshd"
require "pups/runit/unicorn"

module Pups
  def self.log
    # at the moment docker likes this
    @logger ||= Logger.new(STDERR)
  end

  def self.log=(logger)
    @logger = logger
  end
end

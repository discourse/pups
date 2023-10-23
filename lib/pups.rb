# frozen_string_literal: true

require "logger"
require "yaml"

require "pups/version"
require "pups/config"
require "pups/command"
require "pups/exec_command"
require "pups/merge_command"
require "pups/replace_command"
require "pups/file_command"
require "pups/docker"
require "pups/runit"

module Pups
  class ExecError < RuntimeError
    attr_accessor :exit_code
  end

  def self.log
    # at the moment docker likes this
    @logger ||= Logger.new($stderr)
  end

  def self.log=(logger)
    @logger = logger
  end

  def self.silence
    @logger.close if @logger

    @logger = Logger.new(File.open(File::NULL, "w"))
  end
end

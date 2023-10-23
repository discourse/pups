# frozen_string_literal: true

module Pups
  class Runit
    attr_accessor :env, :exec, :cd, :name

    def initialize(name)
      @name = name
    end

    def setup
      `mkdir -p /etc/service/#{name}`
      run = "/etc/service/#{name}/run"
      File.open(run, "w") { |f| f.write(run_script) }
      `chmod +x #{run}`
    end

    def run_script
      "#!/bin/bash
exec 2>&1
#{env_script}
#{cd_script}
#{exec}
"
    end

    def cd_script
      "cd #{@cd}" if @cd
    end

    def env_script
      @env&.map { |k, v| "export #{k}=#{v}" }&.join("\n")
    end
  end
end

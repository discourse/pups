# frozen_string_literal: true

module Pups
  class Command
    def self.run(command, params)
      case command
      when String
        from_str(command, params).run
      when Hash
        from_hash(command, params).run
      end
    end

    def self.interpolate_params(cmd, params)
      Pups::Config.interpolate_params(cmd, params)
    end

    def interpolate_params(cmd)
      Pups::Command.interpolate_params(cmd, @params)
    end
  end
end

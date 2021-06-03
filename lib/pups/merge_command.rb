# frozen_string_literal: true

module Pups
  class MergeCommand < Pups::Command
    attr_reader :filename, :merge_hash

    def self.from_str(command, params)
      new(command, params)
    end

    def self.parse_command(command)
      split = command.split(' ')
      raise ArgumentError, "Invalid merge command #{command}" unless split[-1][0] == '$'

      [split[0..-2].join(' '), split[-1][1..-1]]
    end

    def initialize(command, params)
      @params = params

      filename, target_param = Pups::MergeCommand.parse_command(command)
      @filename = interpolate_params(filename)
      @merge_hash = params[target_param]
    end

    def run
      merged = self.class.deep_merge(YAML.load_file(@filename), @merge_hash)
      File.open(@filename, 'w') { |f| f.write(merged.to_yaml) }
      Pups.log.info("Merge: #{@filename} with: \n#{@merge_hash.inspect}")
    end

    def self.deep_merge(first, second, *args)
      args ||= []
      merge_arrays = args.include? :merge_arrays

      merger = proc { |_key, v1, v2|
        if v1.is_a?(Hash) && v2.is_a?(Hash)
          v1.merge(v2, &merger)
        elsif v1.is_a?(Array) && v2.is_a?(Array)
          merge_arrays ? v1 + v2 : v2
        elsif v2.is_a?(NilClass)
          v1
        else
          v2
        end
      }
      first.merge(second, &merger)
    end
  end
end

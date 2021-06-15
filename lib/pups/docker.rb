# frozen_string_literal: true
require 'shellwords'

class Pups::Docker
  class << self
    def generate_env_arguments(config)
      output = []
      config&.each do |k, v|
        if !v.to_s.empty?
          output << "--env #{k}=#{escape_user_string_literal(v)}"
        end
      end
      normalize_output(output)
    end

    def generate_link_arguments(config)
      output = []
      config&.each do |c|
        output << "--link #{c['link']['name']}:#{c['link']['alias']}"
      end
      normalize_output(output)
    end

    def generate_expose_arguments(config)
      output = []
      config&.each do |c|
        if c.to_s.include?(":")
          output << "--publish #{c}"
        else
          output << "--expose #{c}"
        end
      end
      normalize_output(output)
    end

    def generate_volume_arguments(config)
      output = []
      config&.each do |c|
        output << "--volume #{c['volume']['host']}:#{c['volume']['guest']}"
      end
      normalize_output(output)
    end

    def generate_label_arguments(config)
      output = []
      config&.each do |k, v|
        output << "--label #{k}=#{escape_user_string_literal(v)}"
      end
      normalize_output(output)
    end

    private
    def escape_user_string_literal(str)
      # We need to escape the following strings as they are more likely to contain
      # special characters than any of the other config variables on a Linux system:
      # - the value side of an environment variable
      # - the value side of a label.
      if str.to_s.include?(" ")
        "\"#{Shellwords.escape(str)}\""
      else
        Shellwords.escape(str)
      end
    end

    def normalize_output(output)
      if output.empty?
        ""
      else
        output.join(" ")
      end
    end
  end
end

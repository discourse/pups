# frozen_string_literal: true

module Pups
  class Config
    attr_reader :config, :params
    attr_accessor :ignored

    def self.load_file(config_file, ignored = nil)
      Config.new(YAML.load_file(config_file), ignored)
    rescue Exception
      warn "Failed to parse #{config_file}"
      warn "This is probably a formatting error in #{config_file}"
      warn "Cannot continue. Edit #{config_file} and try again."
      raise
    end

    def self.load_config(config, ignored = nil)
      Config.new(YAML.safe_load(config), ignored)
    end

    def initialize(config, ignored = nil)
      @config = config
      validate!(@config)

      # remove any ignored config elements prior to any more processing
      ignored&.each { |e| @config.delete(e) }

      # Processing of the environment variables occurs first. This merges environment
      # from the yaml templates and process ENV, and templates any variables found
      # either via yaml or ENV.
      @config['env']&.each { |k, v| ENV[k] = v.to_s }
      @config['env_template'] ||= {}

      # Merging env_template variables from ENV and templates.
      ENV.each do |k, v|
        if k.include?('env_template_')
          key = k.gsub('env_template_', '')
          @config['env_template'][key] = v
        end
      end

      # Now transform any templated environment variables prior to copying to params.
      # This has no effect if no env_template was provided.
      @config['env_template']&.each do |k, v|
        ENV.each do |key, val|
          ENV[key] = val.gsub("{{#{k}}}", v.to_s) if val.include?("{{#{k}}}")
        end
      end

      @params = @config['params']
      @params ||= {}
      ENV.each do |k, v|
        @params["$ENV_#{k}"] = v
      end
      inject_hooks
    end

    def validate!(conf)
      # raise proper errors if nodes are missing etc
    end

    def inject_hooks
      return unless hooks = @config['hooks']

      run = @config['run']

      positions = {}
      run.each do |row|
        next unless row.is_a?(Hash)

        command = row.first
        if command[1].is_a?(Hash)
          hook = command[1]['hook']
          positions[hook] = row if hook
        end
      end

      hooks.each do |full, list|
        offset = nil
        name = nil

        if full =~ /^after_/
          name = full[6..-1]
          offset = 1
        end

        if full =~ /^before_/
          name = full[7..-1]
          offset = 0
        end

        index = run.index(positions[name])

        if index && index >= 0
          run.insert(index + offset, *list)
        else
          Pups.log.info "Skipped missing #{full} hook"
        end
      end
    end

    def run
      run_commands
    rescue StandardError => e
      exit_code = 1
      exit_code = e.exit_code if e.is_a?(Pups::ExecError)
      unless exit_code == 77
        puts
        puts
        puts 'FAILED'
        puts '-' * 20
        puts "#{e.class}: #{e}"
        puts "Location of failure: #{e.backtrace[0]}"
        puts "#{@last_command[:command]} failed with the params #{@last_command[:params].inspect}" if @last_command
      end
      exit exit_code
    end

    def run_commands
      @config['run']&.each do |item|
        item.each do |k, v|
          type = case k
                 when 'exec' then Pups::ExecCommand
                 when 'merge' then Pups::MergeCommand
                 when 'replace' then Pups::ReplaceCommand
                 when 'file' then Pups::FileCommand
                 else raise SyntaxError, "Invalid run command #{k}"
          end

          @last_command = { command: k, params: v }
          type.run(v, @params)
        end
      end
    end

    def interpolate_params(cmd)
      self.class.interpolate_params(cmd, @params)
    end

    def self.interpolate_params(cmd, params)
      return unless cmd

      processed = cmd.dup
      params.each do |k, v|
        processed.gsub!("$#{k}", v.to_s)
      end
      processed
    end
  end
end

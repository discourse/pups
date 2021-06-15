# frozen_string_literal: true

module Pups
  class Config
    attr_reader :config, :params

    def initialize(config, ignored = nil)
      @config = config

      # remove any ignored config elements prior to any more processing
      ignored&.each { |e| @config.delete(e) }

      # set some defaults to prevent checks in various functions
      ['env_template', 'env', 'labels', 'params'].each { |key| @config[key] = {} unless @config.has_key?(key) }

      # Order here is important.
      Pups::Config.combine_template_and_process_env(@config, ENV)
      Pups::Config.prepare_env_template_vars(@config['env_template'], ENV)

      # Templating is supported in env and label variables.
      Pups::Config.transform_config_with_templated_vars(@config['env_template'], ENV)
      Pups::Config.transform_config_with_templated_vars(@config['env_template'], @config['env'])
      Pups::Config.transform_config_with_templated_vars(@config['env_template'], @config['labels'])

      @params = @config["params"]
      ENV.each do |k, v|
        @params["$ENV_#{k}"] = v
      end
      inject_hooks
    end

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

    def self.prepare_env_template_vars(env_template, env)
      # Merge env_template variables from env and templates.
      env.each do |k, v|
        if k.include?('env_template_')
          key = k.gsub('env_template_', '')
          env_template[key] = v.to_s
        end
      end
    end

    def self.transform_config_with_templated_vars(env_template, to_transform)
      # Transform any templated variables prior to copying to params.
      # This has no effect if no env_template was provided.
      env_template.each do |k, v|
        to_transform.each do |key, val|
          if val.to_s.include?("{{#{k}}}")
            to_transform[key] = val.gsub("{{#{k}}}", v.to_s)
          end
        end
      end
    end

    def self.combine_template_and_process_env(config, env)
      # Merge all template env variables and process env variables, so that env
      # variables can be provided both by configuration and runtime variables.
      config["env"].each { |k, v| env[k] = v.to_s }
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

    def generate_docker_run_arguments
      output = []
      output << Pups::Docker.generate_env_arguments(config['env'])
      output << Pups::Docker.generate_link_arguments(config['links'])
      output << Pups::Docker.generate_expose_arguments(config['expose'])
      output << Pups::Docker.generate_volume_arguments(config['volumes'])
      output << Pups::Docker.generate_label_arguments(config['labels'])
      output.sort!.join(" ").strip
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

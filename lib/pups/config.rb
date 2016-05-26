class Pups::Config

  attr_reader :config, :params

  def self.load_file(config_file)
    new YAML.load_file(config_file)
  end

  def self.load_config(config)
    new YAML.load(config)
  end

  def initialize(config)
    @config = config
    validate!(@config)
    @params = @config["params"]
    @params ||= {}
    ENV.each do |k,v|
      @params["$ENV_#{k}"] = v
    end
    inject_hooks
  end

  def validate!(conf)
    # raise proper errors if nodes are missing etc
  end

  def inject_hooks
    return unless hooks = @config["hooks"]

    run = @config["run"]

    positions = {}
    run.each do |row|
      if Hash === row
        command = row.first
        if Hash === command[1]
          hook = command[1]["hook"]
          positions[hook] = row if hook
        end
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
  rescue => e
    exit_code = 1
    if Pups::ExecError === e
      exit_code = e.exit_code
    end
    unless exit_code == 77
      puts
      puts
      puts "FAILED"
      puts "-" * 20
      puts "#{e.class}: #{e}"
      puts "Location of failure: #{e.backtrace[0]}"
      if @last_command
        puts "#{@last_command[:command]} failed with the params #{@last_command[:params].inspect}"
      end
    end
    exit exit_code
  end

  def run_commands
    @config["run"].each do |item|
      item.each do |k,v|
        type = case k
                  when "exec" then Pups::ExecCommand
                  when "merge" then Pups::MergeCommand
                  when "replace" then Pups::ReplaceCommand
                  when "file" then Pups::FileCommand
                  else raise SyntaxError.new("Invalid run command #{k}")
              end

        @last_command = { command: k, params: v }
        type.run(v, @params)
      end
    end
  end

  def interpolate_params(cmd)
    self.class.interpolate_params(cmd,@params)
  end

  def self.interpolate_params(cmd, params)
    return unless cmd
    processed = cmd.dup
    params.each do |k,v|
      processed.gsub!("$#{k}", v.to_s)
    end
    processed
  end

end

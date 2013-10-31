class Pups::Config

  def self.load(config_file)
    new YAML.load_file(config_file)
  end

  def initialize(config)
    @config = config
    validate!(@config)
    @params = @config["params"]
  end

  def validate!(conf)
    # raise proper errors if nodes are missing etc
  end


  def run
    load_env
    run_commands
    setup_runit_services
  end

  def load_env
    @config["env"].each do |k,v|
      ENV[k.to_s] = v.to_s
    end if @config["env"]
    Pups.log.info "Environment Loaded"
  end

  def run_commands
    @config["run"].each do |item|
      item.each do |k,v|
        type = case k
                  when "exec" then Pups::ExecCommand
                  when "merge" then Pups::MergeCommand
                  when "replace" then Pups::MergeCommand
                  else raise SyntaxError.new("Invalid run command #{k}")
              end

        type.run(v, @params)
      end
    end
  end

  def setup_runit_services
    return unless runit = @config["runit"]

    runit.each do |k,v|
      service = Pups::Runit.new(k)
      service.exec = interpolate_params(v["exec"])
      service.cd = interpolate_params(v["cd"])
      service.env = @config["env"]
      service.setup
    end
  end

  def interpolate_params(cmd)
    self.class.interpolate_params(cmd,@params)
  end

  def self.interpolate_params(cmd, params)
    return unless cmd
    processed = cmd.dup
    params.each do |k,v|
      processed.gsub!("$#{k}", v)
    end
    processed
  end

end

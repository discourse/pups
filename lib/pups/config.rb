class Pups::Config

  def initialize(config_file)
    @config = YAML.load_file(config_file)
    validate!(@config)
    @app_root = @config["app"]["root"]
  end

  def validate!(conf)
    # raise proper errors if nodes are missing etc
  end

  def app
    @config["app"]
  end

  def startup
    load_env
    ensure_git_version
    bootstrap
    merge_database_yml
    migrate
    start_daemons
  end

  def load_env
    @config["env"].each do |k,v|
      ENV[k.to_s] = v.to_s
    end if @config["env"]
    Pups.log.info "Environment Loaded"
  end

  def ensure_git_version
    Pups.log.info run("git reset --hard")
    Pups.log.info run("git pull")
  end

  def bootstrap
    app["bootstrap"].each do |command|
      run command
    end
  end

  def merge_database_yml
    merge = app["database.yml"]
    return unless merge

    database_yml = "#{@app_root}/config/database.yml"

    merged = deep_merge(YAML.load_file(database_yml), merge)

    File.open(database_yml, "w"){ |f|
      f.write merged.to_yaml
    }
    Pups.log.info("Merged database.yml")
  end

  def migrate
    run "bundle exec rake db:migrate"
  end

  def start_daemons
    start_sshd
    start_unicorn
  end

  def start_unicorn
    run "unicorn -c config/unicorn.conf.rb"
  end

  def start_sshd
    run "mkdir -p /root/.ssh"
    if sshd = @config["sshd"]
      id_rsa = sshd["id_rsa"]
      if id_rsa
        File.open("/root/.ssh/authorized_keys", "w") do |f|
          f.write(id_rsa)
        end
      end
    end
    run "mkdir -p /var/run/sshd"
    Pups::Process.spawn("/usr/sbin/sshd")
  end

  protected

  def run(command)
    cmd = "cd #{@app_root} && #{command}"
    Pups.log.info "> " << cmd
    `#{cmd}`
  end

  def deep_merge(first,second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    first.merge(second, &merger)
  end
end

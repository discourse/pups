class Pups::Cli

  def self.usage
    puts "Usage: pups FILE or pups --stdin"
    exit 1
  end
  def self.run(args)
    if args.length != 1
      usage
    end

    begin
      Pups.log.info("Loading #{args[0]}")
      if args[0] == "--stdin"
        conf = STDIN.readlines.join
        split = conf.split("_FILE_SEPERATOR_")

        conf = nil
        split.each do |data|
          current = YAML.load(data.strip)
          if conf
            conf = Pups::MergeCommand.deep_merge(conf, current, :merge_arrays)
          else
            conf = current
          end
        end

        config = Pups::Config.new(conf)
      else
        config = Pups::Config.load_file(args[0])
      end
      config.run
    ensure
      Pups::ExecCommand.terminate_async
    end
  rescue Pups::ExecError => e
    # 77 is special it means retry
    unless e.exit_code == 77
      STDERR.puts e.message
    end
    exit e.exit_code
  end
end

class Pups::Cli

  def self.usage
    puts "Usage: pups FILE or pups --stdin"
    exit 1
  end
  def self.run(args)
    if args.length != 1
      usage
    end

    Pups.log.info("Loading #{args[0]}")
    if args[0] == "--stdin"
      config = Pups::Config.load_config(STDIN.readlines.join)
    else
      config = Pups::Config.load_file(args[0])
    end
    config.run
    Pups::ExecCommand.terminate_async
  end
end

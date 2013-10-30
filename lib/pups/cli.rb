class Pups::Cli
  def self.run(args)
    if args.length != 1
      raise ArgumentError.new("Expecting config file name")
    end

    config = Pups::Config.new(args[0])

    config.startup

    while true
      sleep 1
    end

    trap "TERM" do
      Pups.log.warn("Terminating child apps.")
      Pups::Process.kill_all("TERM")
      exit
    end
  end
end

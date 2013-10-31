class Pups::Cli
  def self.run(args)
    if args.length != 1
      raise ArgumentError.new("Expecting config file name")
    end

    Pups.log.info("Loading #{args[0]}")
    config = Pups::Config.load(args[0])
    config.run
  end
end

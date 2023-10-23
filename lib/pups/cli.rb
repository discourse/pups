# frozen_string_literal: true

require "optparse"

module Pups
  class Cli
    def self.opts
      OptionParser.new do |opts|
        opts.banner = "Usage: pups [FILE|--stdin]"
        opts.on("--stdin", "Read input from stdin.")
        opts.on("--quiet", "Don't print any logs.")
        opts.on(
          "--ignore <element(s)>",
          Array,
          "Ignore these template configuration elements, multiple elements can be provided (comma-delimited)."
        )
        opts.on(
          "--gen-docker-run-args",
          "Output arguments from the pups configuration for input into a docker run command. All other pups config is ignored."
        )
        opts.on("--tags <tag(s)>", Array, "Only run tagged commands.")
        opts.on(
          "--skip-tags <tag(s)>",
          Array,
          "Run all but listed tagged commands."
        )
        opts.on("-h", "--help") do
          puts opts
          exit
        end
      end
    end

    def self.parse_args(args)
      options = {}
      opts.parse!(args, into: options)
      options
    end

    def self.run(args)
      options = parse_args(args)
      input_file = options[:stdin] ? "stdin" : args.last
      unless input_file
        puts opts.parse!(%w[--help])
        exit
      end

      Pups.silence if options[:quiet]

      Pups.log.info("Reading from #{input_file}")

      if options[:stdin]
        conf = $stdin.readlines.join
        split = conf.split("_FILE_SEPERATOR_")

        conf = nil
        split.each do |data|
          current = YAML.safe_load(data.strip)
          conf =
            if conf
              Pups::MergeCommand.deep_merge(conf, current, :merge_arrays)
            else
              current
            end
        end

        config =
          Pups::Config.new(
            conf,
            options[:ignore],
            tags: options[:tags],
            skip_tags: options[:"skip-tags"]
          )
      else
        config =
          Pups::Config.load_file(
            input_file,
            options[:ignore],
            tags: options[:tags],
            skip_tags: options[:"skip-tags"]
          )
      end

      if options[:"gen-docker-run-args"]
        print config.generate_docker_run_arguments
        return
      end

      config.run
    ensure
      Pups::ExecCommand.terminate_async
    end
  end
end

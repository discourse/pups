require 'optparse'

class Pups::Cli

  def self.run(args)
    options = {}
    opt = OptionParser.new do |opts|
      opts.banner = 'Usage: pups [FILE|--stdin]'
      opts.on('--stdin', 'Read input from stdin.')
      opts.on('-h', '--help') do
        puts opts
        exit
      end
    end
    opt.parse!(into: options)

    input_file = options[:stdin] ? "stdin" : ARGV.last
    if !input_file
      puts opt
      exit
    end

    Pups.log.info("Reading from #{input_file}")

    if options[:stdin]
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
      config = Pups::Config.load_file(input_file)
    end

    config.run
  ensure
    Pups::ExecCommand.terminate_async
  end
end

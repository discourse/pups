class Pups::MergeCommand < Pups::Command
  attr_reader :filename
  attr_reader :merge_hash

  def self.from_str(command, params)
    new(command,params)
  end

  def self.parse_command(command)
    split = command.split(" ")
    raise ArgumentError.new("Invalid merge command #{command}") unless split[-1][0] == "$"

    [split[0..-2].join(" ") , split[-1][1..-1]]
  end

  def initialize(command, params)
    @params = params

    filename, target_param = Pups::MergeCommand.parse_command(command)
    @filename = interpolate_params(filename)
    @merge_hash = params[target_param]
  end

  def run
    merged = self.class.deep_merge(YAML.load_file(@filename), @merge_hash)
    File.open(@filename,"w"){|f| f.write(merged.to_yaml) }
  end

  def self.deep_merge(first,second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    first.merge(second, &merger)
  end

end

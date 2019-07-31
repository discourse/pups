class Pups::FileCommand < Pups::Command
  attr_accessor :path, :contents, :params, :type, :chmod, :chown

  def self.from_hash(hash, params)
    command = new
    command.path = hash["path"]
    command.contents = hash["contents"]
    command.chmod = hash["chmod"]
    command.chown = hash["chown"]
    command.params = params

    command
  end

  def initialize
    @params = {}
    @type = :bash
  end

  def params=(p)
    @params = p
  end

  def run
    path = interpolate_params(@path)

    `mkdir -p #{File.dirname(path)}`
    File.open(path, "w") do |f|
      f.write(interpolate_params(contents))
    end
    if @chmod
      `chmod #{@chmod} #{path}`
    end
    if @chown
      `chown #{@chown} #{path}`
    end
    Pups.log.info("File > #{path}  chmod: #{@chmod}  chown: #{@chown}")
  end

end


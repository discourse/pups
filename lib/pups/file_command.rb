class Pups::FileCommand < Pups::Command
  attr_accessor :path, :contents, :params, :type, :chmod

  def self.from_hash(hash, params)
    command = new
    command.path = hash["path"]
    command.contents = hash["contents"]
    command.chmod = hash["chmod"]
    command.params = params

    command
  end

  def initialize
    @params = {}
    @type = :bash
  end

  def params=(p)
    return @params = p unless type == :bash

    @params = p.dup
    @params.each do |k,v|
      if Hash === v
        @params[k] = v.map{|k,v| "export #{k}=#{v}"}.join("\n")
      end
    end
  end

  def run
    path = interpolate_params(@path)

    `mkdir -p #{File.dirname(path)}`
    File.open(@path, "w") do |f|
      f.write(interpolate_params(contents))
    end
    if @chmod
      `chmod #{@chmod} #{path}`
    end
    Pups.log.info("File > #{path}  chmod: #{@chmod}")
  end

end


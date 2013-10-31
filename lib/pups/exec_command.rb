class Pups::ExecCommand < Pups::Command
  attr_reader :commands
  attr_reader :cd

  def self.from_hash(hash, params)
    cmd = new(params, hash["cd"])

    case c = hash["cmd"]
    when String then cmd.add(c)
    when Array then c.each{|i| cmd.add(i)}
    end

    cmd
  end

  def self.from_str(str, params)
    cmd = new(params)
    cmd.add(str)
    cmd
  end

  def initialize(params, cd = nil)
    @commands = []
    @params = params
    @cd = interpolate_params(cd)
  end

  def add(cmd)
    @commands << process_params(cmd)
  end

  def run
    commands.each do |command|
      Pups.log.info("> #{command}")
      Pups.log.info(`#{command}`)
    end
  end


end

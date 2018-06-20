require 'timeout'

class Pups::ExecCommand < Pups::Command
  attr_reader :commands, :cd
  attr_accessor :background, :raise_on_fail, :stdin, :stop_signal

  def self.terminate_async(opts={})

    return unless defined? @@asyncs

    Pups.log.info("Terminating async processes")

    @@asyncs.each do |async|
      Pups.log.info("Sending #{async[:stop_signal]} to #{async[:command]} pid: #{async[:pid]}")
      Process.kill(async[:stop_signal],async[:pid]) rescue nil
    end

    @@asyncs.map do |async|
      Thread.new do
        begin
          Timeout.timeout(opts[:wait] || 10) do
            Process.wait(async[:pid]) rescue nil
          end
        rescue Timeout::Error
          Pups.log.info("#{async[:command]} pid:#{async[:pid]} did not terminate cleanly, forcing termination!")
          begin
            Process.kill("KILL",async[:pid])
            Process.wait(async[:pid])
          rescue Errno::ESRCH
          rescue Errno::ECHILD
          end

        end
      end
    end.each(&:join)

  end

  def self.from_hash(hash, params)
    cmd = new(params, hash["cd"])

    case c = hash["cmd"]
    when String then cmd.add(c)
    when Array then c.each{|i| cmd.add(i)}
    end

    cmd.background = hash["background"]
    cmd.stop_signal = hash["stop_signal"] || "TERM"
    cmd.raise_on_fail = hash["raise_on_fail"] if hash.key? "raise_on_fail"
    cmd.stdin = interpolate_params(hash["stdin"], params)

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
    @raise_on_fail = true
  end

  def add(cmd)
    @commands << process_params(cmd)
  end

  def run
    commands.each do |command|
      Pups.log.info("> #{command}")
      pid = spawn(command)
      Pups.log.info(@result.readlines.join("\n")) if @result
      pid
    end
  rescue
    raise if @raise_on_fail
  end

  def spawn(command)
    if background
      pid = Process.spawn(command)
      (@@asyncs ||= []) << {pid: pid, command: command, stop_signal: (stop_signal || "TERM")}
      Thread.new do
        begin
          Process.wait(pid)
        rescue Errno::ECHILD
          # already exited so skip
        end
        @@asyncs.delete_if{|async| async[:pid] == pid}
      end
      return pid
    end

    IO.popen(command, "w+") do |f|
      if stdin
        # need a way to get stdout without blocking
        Pups.log.info(stdin)
        f.write stdin
        f.close
      else
        Pups.log.info(f.readlines.join)
      end
    end

    unless $? == 0
      err = Pups::ExecError.new("#{command} failed with return #{$?.inspect}")
      err.exit_code = $?.exitstatus
      raise err
    end

    nil

  end

  def process_params(cmd)
    processed = interpolate_params(cmd)
    @cd ? "cd #{cd} && #{processed}" : processed
  end

end

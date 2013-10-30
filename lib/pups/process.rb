class Pups::Process
  def self.pids
    @@pids ||= []
  end

  def self.spawn(*args)
    pid = Process.spawn(*args)
    Pups.log.info "Spawned #{args.inspect} pid: #{pid}"
    pids << pid

    Thread.start do
      Process.wait(pid)
      pids.delete(pid)
    end

    pid
  end

  def self.kill_all(signal)
    pids.each do |pid|
      Process.kill(signal,pid)
      Pups.log.info("Sent #{signal} to #{pid}")
    end
  end

  def spawn(*args)
    self.class.spawn(*args)
  end

end

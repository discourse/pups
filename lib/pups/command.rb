class Pups::Command

  def self.run(command,params)
    case command
      when String then self.from_str(command,params).run
      when Hash then self.from_hash(command,params).run
    end
  end

  def process_params(cmd)
    processed = cmd.dup
    @params.each do |k,v|
      processed.gsub!("$#{k}", v)
    end
    @cd ? "cd #{cd} && #{processed}" : processed
  end
end

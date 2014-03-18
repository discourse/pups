class Pups::ReplaceCommand < Pups::Command
  attr_accessor :text, :from, :to, :filename, :direction

  def self.from_hash(hash, params)
    replacer = new(params)
    replacer.from = guess_replace_type(hash["from"])
    replacer.to = guess_replace_type(hash["to"])
    replacer.text = File.read(hash["filename"])
    replacer.filename = hash["filename"]
    replacer.direction = hash["direction"].to_sym if hash["direction"]
    replacer
  end

  def self.guess_replace_type(item)
    # evaling to get all the regex flags easily
    item[0] == "/" ? eval(item) : item
  end

  def initialize(params)
    @params = params
  end

  def replaced_text
    new_to = to
    if String === to
      new_to = interpolate_params(to)
    end
    if direction == :reverse
      index = text.rindex(from)
      text[0..index-1] << text[index..-1].sub(from,new_to)
    else
      text.sub(from,new_to)
    end
  end

  def run
    Pups.log.info("Replacing #{from.to_s} with #{to.to_s} in #{filename}")
    File.open(filename, "w"){|f| f.write replaced_text }
  end
end

require 'test_helper'
require 'tempfile'

module Pups
  class MergeCommandTest < MiniTest::Test

    def test_merges

      source = <<YAML
user:
  name: "bob"
  password: "xyz"
YAML

      f = Tempfile.new("test")
      f.write source
      f.close

      merge = <<YAML
user:
  name: "bob2"
YAML

    MergeCommand.from_str("#{f.path} $yaml", {"yaml" => YAML.load(merge) }).run

    changed = YAML.load_file(f.path)

    assert_equal({"user" => {
      "name" => "bob2",
      "password" => "xyz"
    }}, changed)

    ensure
      f.unlink
    end
  end
end

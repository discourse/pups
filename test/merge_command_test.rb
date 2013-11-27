require 'test_helper'
require 'tempfile'

module Pups
  class MergeCommandTest < MiniTest::Test
    def test_deep_merge_arrays
      a = {a: {a: ["hi",1]}}
      b = {a: {a: ["hi",2]}}
      c = {a: {}}

      d = Pups::MergeCommand.deep_merge(a,b,:merge_arrays)
      d = Pups::MergeCommand.deep_merge(d,c,:merge_arrays)

      assert_equal(["hi", 1,"hi", 2], d[:a][:a])
    end

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

# frozen_string_literal: true

require "test_helper"
require "tempfile"

module Pups
  class MergeCommandTest < ::Minitest::Test
    def test_deep_merge_arrays
      a = { a: { a: ["hi", 1] } }
      b = { a: { a: ["hi", 2] } }
      c = { a: {} }

      d = Pups::MergeCommand.deep_merge(a, b, :merge_arrays)
      d = Pups::MergeCommand.deep_merge(d, c, :merge_arrays)

      assert_equal(["hi", 1, "hi", 2], d[:a][:a])
    end

    def test_merges
      source = <<~YAML
        user:
          name: "bob"
          password: "xyz"
      YAML

      f = Tempfile.new("test")
      f.write source
      f.close

      merge = <<~YAML
        user:
          name: "bob2"
      YAML

      MergeCommand.from_str(
        "#{f.path} $yaml",
        { "yaml" => YAML.safe_load(merge) }
      ).run

      changed = YAML.load_file(f.path)

      assert_equal(
        { "user" => { "name" => "bob2", "password" => "xyz" } },
        changed
      )

      def test_deep_merge_nil
        a = { param: { venison: "yes please" } }
        b = { param: nil }

        r1 = Pups::MergeCommand.deep_merge(a, b)
        r2 = Pups::MergeCommand.deep_merge(b, a)

        assert_equal({ venison: "yes please" }, r1[:param])
        assert_equal({ venison: "yes please" }, r2[:param])
      end
    ensure
      f.unlink
    end
  end
end

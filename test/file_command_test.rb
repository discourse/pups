# frozen_string_literal: true

require "test_helper"
require "tempfile"

module Pups
  class FileCommandTest < ::Minitest::Test
    def test_simple_file_creation
      tmp = Tempfile.new("test")
      tmp.write("x")
      tmp.close

      cmd = FileCommand.new
      cmd.path = tmp.path
      cmd.contents = "hello $world"
      cmd.params = { "world" => "world" }
      cmd.run

      assert_equal("hello world", File.read(tmp.path))
    ensure
      tmp.close
      tmp.unlink
    end
  end
end

require 'test_helper'
require 'tempfile'

module Pups
  class FileCommandTest < MiniTest::Test

    def test_simple_file_creation
      tmp = Tempfile.new("test")
      tmp.write("x")
      tmp.close


      cmd = FileCommand.new
      cmd.path = tmp.path
      cmd.contents = "hello $world"
      cmd.params = {"world" => "world"}
      cmd.run

      assert_equal("hello world",
                    File.read(tmp.path))
    ensure
      tmp.close
      tmp.unlink
    end


    def test_interpolate_env
      cmd = FileCommand.new
      cmd.params = {"env" => { "FOO" => "1", "BAR" => "bar"} }

      assert_equal(
"export FOO=1
export BAR=bar",
        cmd.interpolate_params("$env"))
    end

  end
end

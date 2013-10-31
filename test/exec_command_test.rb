require 'test_helper'

module Pups
  class ExecCommandTest < MiniTest::Test

    def from_str(str, params={})
      ExecCommand.from_str(str, params).commands
    end

    def from_hash(hash, params={})
      ExecCommand.from_hash(hash, params).commands
    end

    def test_simple_str_command
      assert_equal(["do_something"],
           from_str("do_something"))
    end

    def test_simple_str_command_with_param
      assert_equal(["hello world"],
           from_str("hello $bob", {"bob" => "world"}))
    end

    def test_nested_command
      assert_equal(["first"],
         from_hash("cmd" => "first"))
    end

    def test_multi_commands
      assert_equal(["first","second"],
          from_hash("cmd" => ["first","second"]))
    end

    def test_multi_commands_with_home
      assert_equal(["cd /home/sam && first",
                    "cd /home/sam && second"],
          from_hash("cmd" => ["first","second"],
                    "cd" => "/home/sam"))
    end

    def test_fails_for_bad_command
      assert_raises(Errno::ENOENT) do
        ExecCommand.from_str("boom",{}).run
      end
    end

  end
end

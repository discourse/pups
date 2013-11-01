require 'test_helper'
require 'tempfile'

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

    def test_exec_works
      ExecCommand.from_str("ls",{}).run
    end

    def test_fails_for_bad_command
      assert_raises(Errno::ENOENT) do
        ExecCommand.from_str("boom",{}).run
      end
    end

    def test_backgroud_task_do_not_fail
      cmd = ExecCommand.new({})
      cmd.background = true
      cmd.add("sleep 10 && exit 1")
      cmd.run
    end

    def test_raise_on_fail
      cmd = ExecCommand.new({})
      cmd.add("chgrp -a")
      cmd.raise_on_fail = false
      cmd.run
    end

    def test_stdin

      `touch test_file`
      cmd = ExecCommand.new({})
      cmd.add("read test ; echo $test > test_file")
      cmd.stdin = "hello"
      cmd.run

      assert_equal("hello\n", File.read("test_file"))

    ensure
      File.delete("test_file")
    end

    def test_fails_for_non_zero_exit
      assert_raises(RuntimeError) do
        ExecCommand.from_str("chgrp -a",{}).run
      end
    end

  end
end

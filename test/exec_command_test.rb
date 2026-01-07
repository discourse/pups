# frozen_string_literal: true

require "test_helper"
require "tempfile"

module Pups
  class ExecCommandTest < ::Minitest::Test
    def from_str(str, params = {})
      ExecCommand.from_str(str, params).commands
    end

    def from_hash(hash, params = {})
      ExecCommand.from_hash(hash, params).commands
    end

    def test_simple_str_command
      assert_equal(["do_something"], from_str("do_something"))
    end

    def test_simple_str_command_with_param
      assert_equal(
        ["hello world"],
        from_str("hello $bob", { "bob" => "world" })
      )
    end

    def test_nested_command
      assert_equal(["first"], from_hash("cmd" => "first"))
    end

    def test_multi_commands
      assert_equal(%w[first second], from_hash("cmd" => %w[first second]))
    end

    def test_multi_commands_with_home
      assert_equal(
        ["cd /home/sam && first", "cd /home/sam && second"],
        from_hash("cmd" => %w[first second], "cd" => "/home/sam")
      )
    end

    def test_exec_works
      ExecCommand.from_str("ls", {}).run
    end

    def test_fails_for_bad_command
      assert_raises(Errno::ENOENT) { ExecCommand.from_str("boom", {}).run }
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
      assert_raises(Pups::ExecError) do
        ExecCommand.from_str("chgrp -a", {}).run
      end
    end

    def test_can_terminate_async
      cmd = ExecCommand.new({})
      cmd.background = true
      pid = cmd.spawn("sleep 10 && exit 1")
      ExecCommand.terminate_async
      assert_raises(Errno::ECHILD) { Process.waitpid(pid, Process::WNOHANG) }
    end

    def test_can_terminate_rogues
      cmd = ExecCommand.new({})
      cmd.background = true
      pid = cmd.spawn('trap "echo TERM && sleep 100" TERM ; sleep 100')
      # we need to give bash enough time to trap
      sleep 0.01

      ExecCommand.terminate_async(wait: 0.1)

      assert_raises(Errno::ECHILD) { Process.waitpid(pid, Process::WNOHANG) }
    end

    def test_stdout_streaming
      # Starts a long-running process that outputs immediately
      # and then watches a file before quitting.
      # If stdout is properly streamed, we should see the output
      # immediately rather than waiting for the process to end.

      signal_file = Tempfile.new("signal")
      signal_path = signal_file.path
      signal_file.close

      reader, writer = IO.pipe
      original_stdout = $stdout.dup

      $stdout.reopen(writer)

      cmd = ExecCommand.new({})
      cmd.add("echo 'streamed output'; while [ ! -s #{signal_path} ]; do sleep 0.1; done")

      thread = Thread.new { cmd.run }

      # Wait for output - if streaming works, it appears immediately
      # If buffered, it would never appear since command loops until signaled
      ready = IO.select([reader], nil, nil, 2)
      assert ready, "Output should be available before command completes"

      output = reader.read_nonblock(1000)
      assert_includes(output, "streamed output")
    ensure
      $stdout.reopen(original_stdout) if original_stdout

      writer&.close
      reader&.close

      File.write(signal_path, "done")
      signal_file&.unlink

      thread.join(2)
    end
  end
end

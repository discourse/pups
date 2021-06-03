# frozen_string_literal: true

require 'test_helper'
require 'tempfile'

module Pups
  class ExecCommandTest < MiniTest::Test
    def from_str(str, params = {})
      ExecCommand.from_str(str, params).commands
    end

    def from_hash(hash, params = {})
      ExecCommand.from_hash(hash, params).commands
    end

    def test_simple_str_command
      assert_equal(['do_something'],
                   from_str('do_something'))
    end

    def test_simple_str_command_with_param
      assert_equal(['hello world'],
                   from_str('hello $bob', { 'bob' => 'world' }))
    end

    def test_nested_command
      assert_equal(['first'],
                   from_hash('cmd' => 'first'))
    end

    def test_multi_commands
      assert_equal(%w[first second],
                   from_hash('cmd' => %w[first second]))
    end

    def test_multi_commands_with_home
      assert_equal(['cd /home/sam && first',
                    'cd /home/sam && second'],
                   from_hash('cmd' => %w[first second],
                             'cd' => '/home/sam'))
    end

    def test_exec_works
      ExecCommand.from_str('ls', {}).run
    end

    def test_fails_for_bad_command
      assert_raises(Errno::ENOENT) do
        ExecCommand.from_str('boom', {}).run
      end
    end

    def test_backgroud_task_do_not_fail
      cmd = ExecCommand.new({})
      cmd.background = true
      cmd.add('sleep 10 && exit 1')
      cmd.run
    end

    def test_raise_on_fail
      cmd = ExecCommand.new({})
      cmd.add('chgrp -a')
      cmd.raise_on_fail = false
      cmd.run
    end

    def test_stdin
      `touch test_file`
      cmd = ExecCommand.new({})
      cmd.add('read test ; echo $test > test_file')
      cmd.stdin = 'hello'
      cmd.run

      assert_equal("hello\n", File.read('test_file'))
    ensure
      File.delete('test_file')
    end

    def test_fails_for_non_zero_exit
      assert_raises(Pups::ExecError) do
        ExecCommand.from_str('chgrp -a', {}).run
      end
    end

    def test_can_terminate_async
      cmd = ExecCommand.new({})
      cmd.background = true
      pid = cmd.spawn('sleep 10 && exit 1')
      ExecCommand.terminate_async
      assert_raises(Errno::ECHILD) do
        Process.waitpid(pid, Process::WNOHANG)
      end
    end

    def test_can_terminate_rogues
      cmd = ExecCommand.new({})
      cmd.background = true
      pid = cmd.spawn('trap "echo TERM && sleep 100" TERM ; sleep 100')
      # we need to give bash enough time to trap
      sleep 0.01

      ExecCommand.terminate_async(wait: 0.1)

      assert_raises(Errno::ECHILD) do
        Process.waitpid(pid, Process::WNOHANG)
      end
    end
  end
end

# frozen_string_literal: true

require 'test_helper'
require 'tempfile'
require 'stringio'

module Pups
  class CliTest < MiniTest::Test
    def test_cli_option_parsing_stdin
      options = Cli.parse_args(['--stdin'])
      assert_equal(true, options[:stdin])
    end

    def test_cli_option_parsing_none
      options = Cli.parse_args([])
      assert_nil(options[:stdin])
    end

    def test_cli_read_config_from_file
      # for testing output
      f = Tempfile.new('test_output')
      f.close

      # for testing input
      cf = Tempfile.new('test_config')
      cf.puts <<~YAML
        params:
          run: #{f.path}
        run:
          - exec: echo hello world >> #{f.path}
      YAML
      cf.close

      Cli.run([cf.path])
      assert_equal('hello world', File.read(f.path).strip)
    end
  end
end

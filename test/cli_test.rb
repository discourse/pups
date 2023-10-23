# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "stringio"

module Pups
  class CliTest < ::Minitest::Test
    def test_cli_option_parsing_stdin
      options = Cli.parse_args(["--stdin"])
      assert_equal(true, options[:stdin])
    end

    def test_cli_option_parsing_none
      options = Cli.parse_args([])
      assert_nil(options[:stdin])
    end

    def test_cli_read_config_from_file
      # for testing output
      f = Tempfile.new("test_output")
      f.close

      # for testing input
      cf = Tempfile.new("test_config")
      cf.puts <<~YAML
      params:
        run: #{f.path}
      run:
        - exec: echo hello world >> #{f.path}
      YAML
      cf.close

      Cli.run([cf.path])
      assert_equal("hello world", File.read(f.path).strip)
    end

    def test_cli_ignore_config_element
      # for testing output
      f = Tempfile.new("test_output")
      f.close

      # for testing input
      cf = Tempfile.new("test_config")
      cf.puts <<~YAML
        env:
          MY_IGNORED_VAR: a_word
        params:
          a_param_var: another_word
        run:
          - exec: echo repeating $MY_IGNORED_VAR and also $a_param_var >> #{f.path}
      YAML
      cf.close

      Cli.run(["--ignore", "env,params", cf.path])
      assert_equal("repeating and also", File.read(f.path).strip)
    end

    def test_cli_gen_docker_run_args_ignores_other_config
      # When generating the docker run arguments it should ignore other template configuration
      # like 'run' directives.

      # for testing output
      f = Tempfile.new("test_output")
      f.close

      # for testing input
      cf = Tempfile.new("test_config")
      cf.puts <<~YAML
      env:
        foo: 1
        bar: 5
        baz: 'hello_{{spam}}'
      env_template:
        spam: 'eggs'
        config: my_app
      params:
        run: #{f.path}
      run:
        - exec: echo hello world >> #{f.path}
      expose:
        - "2222:22"
        - "127.0.0.1:20080:80"
        - 5555
      volumes:
        - volume:
            host: /var/discourse/shared
            guest: /shared
        - volume:
            host: /bar
            guest: /baz
      links:
        - link:
            name: postgres
            alias: postgres
        - link:
            name: foo
            alias: bar
      labels:
        monitor: "true"
        app_name: "{{config}}_discourse"
      YAML
      cf.close

      expected = []
      expected << "--env foo=1 --env bar=5 --env baz=hello_eggs"
      expected << "--publish 2222:22 --publish 127.0.0.1:20080:80 --expose 5555"
      expected << "--volume /var/discourse/shared:/shared --volume /bar:/baz"
      expected << "--link postgres:postgres --link foo:bar"
      expected << "--label monitor=true --label app_name=my_app_discourse"
      expected.sort!

      assert_equal("", File.read(f.path).strip)
      assert_output(expected.join(" ")) do
        Cli.run(["--gen-docker-run-args", cf.path])
      end
    end

    def test_cli_tags
      # for testing output
      f = Tempfile.new("test_output")
      f.close

      # for testing input
      cf = Tempfile.new("test_config")
      cf.puts <<~YAML
        run:
          - exec:
              tag: '1'
              cmd: echo 1 >> #{f.path}
          - exec:
              tag: '2'
              cmd: echo 2 >> #{f.path}
          - exec:
              tag: '3'
              cmd: echo 3 >> #{f.path}
      YAML
      cf.close

      Cli.run(["--tags", "1,3", cf.path])
      assert_equal("1\n3", File.read(f.path).strip)
    end
    def test_cli_skip_tags
      # for testing output
      f = Tempfile.new("test_output")
      f.close

      # for testing input
      cf = Tempfile.new("test_config")
      cf.puts <<~YAML
        run:
          - exec:
              tag: '1'
              cmd: echo 1 >> #{f.path}
          - exec:
              tag: '2'
              cmd: echo 2 >> #{f.path}
          - exec:
              tag: '3'
              cmd: echo 3 >> #{f.path}
      YAML
      cf.close

      Cli.run(["--skip-tags", "1,3", cf.path])
      assert_equal("2", File.read(f.path).strip)
    end
  end
end

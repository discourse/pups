# frozen_string_literal: true
require 'test_helper'
require 'tempfile'
require 'shellwords'

module Pups
  class DockerTest < MiniTest::Test
    def test_gen_env_arguments
      yaml = <<~YAML
      env:
        foo: 1
        bar: 2
        baz: 'hello_{{spam}}'
      env_template:
        spam: 'eggs'
      YAML

      config = Config.load_config(yaml)
      Config.transform_config_with_templated_vars(config.config['env_template'], config.config["env"])
      args = Docker.generate_env_arguments(config.config["env"])
      assert_equal("--env foo=1 --env bar=2 --env baz=hello_eggs", args)
    end

    def test_gen_env_arguments_empty
      yaml = <<~YAML
      env:
        foo: 1
        bar: 2
        baz: ''
      YAML

      config = Config.load_config(yaml)
      Config.transform_config_with_templated_vars(config.config['env_template'], config.config["env"])
      args = Docker.generate_env_arguments(config.config["env"])
      assert_equal("--env foo=1 --env bar=2", args)
    end

    def test_gen_env_arguments_escaped
      yaml = <<~YAML
      env:
        password: "{{spam}}*`echo`@e$t| = >>$()&list;#"
      env_template:
        spam: 'eggs'
      YAML

      config = Config.load_config(yaml)
      Config.transform_config_with_templated_vars(config.config['env_template'], config.config["env"])
      args = Docker.generate_env_arguments(config.config["env"])
      assert_equal("--env password=#{Shellwords.escape('eggs*`echo`@e$t| = >>$()&list;#')}", args)
    end

    def test_gen_env_arguments_quoted_with_a_space
      yaml = <<~YAML
      env:
        a_variable: here is a sentence
      YAML

      config = Config.load_config(yaml)
      Config.transform_config_with_templated_vars(config.config['env_template'], config.config["env"])
      args = Docker.generate_env_arguments(config.config["env"])
      assert_equal('--env a_variable=here\ is\ a\ sentence', args)
    end

    def test_gen_env_arguments_newline
      pw = <<~PW
this password is
  a weird one
      PW

      yaml = <<~YAML
      env:
        password: "#{pw}"
      env_template:
        spam: 'eggs'
      YAML

      config = Config.load_config(yaml)
      Config.transform_config_with_templated_vars(config.config['env_template'], config.config["env"])
      args = Docker.generate_env_arguments(config.config["env"])
      assert_equal('--env password=this\ password\ is\ a\ weird\ one\ ', args)
    end

    def test_gen_expose_arguments
      yaml = <<~YAML
      expose:
        - "2222:22"
        - "127.0.0.1:20080:80"
        - 5555
      YAML

      config = Config.load_config(yaml)
      args = Docker.generate_expose_arguments(config.config["expose"])
      assert_equal("--publish 2222:22 --publish 127.0.0.1:20080:80 --expose 5555", args)
    end

    def test_gen_volume_arguments
      yaml = <<~YAML
      volumes:
        - volume:
            host: /var/discourse/shared
            guest: /shared
        - volume:
            host: /bar
            guest: /baz
      YAML

      config = Config.load_config(yaml)
      args = Docker.generate_volume_arguments(config.config["volumes"])
      assert_equal("--volume /var/discourse/shared:/shared --volume /bar:/baz", args)
    end

    def test_gen_link_arguments
      yaml = <<~YAML
      links:
        - link:
            name: postgres
            alias: postgres
        - link:
            name: foo
            alias: bar
      YAML

      config = Config.load_config(yaml)
      args = Docker.generate_link_arguments(config.config["links"])
      assert_equal("--link postgres:postgres --link foo:bar", args)
    end

    def test_gen_label_arguments
      yaml = <<~YAML
      env_template:
        config: my_app
      labels:
        monitor: "true"
        app_name: "{{config}}_discourse"
      YAML

      config = Config.load_config(yaml)
      Config.transform_config_with_templated_vars(config.config['env_template'], config.config["labels"])
      args = Docker.generate_label_arguments(config.config["labels"])
      assert_equal("--label monitor=true --label app_name=my_app_discourse", args)
    end

    def test_gen_label_arguments_escaped
      yaml = <<~YAML
      labels:
        app_name: "{{config}}'s_di$course"
      env_template:
        config: my_app
      YAML

      config = Config.load_config(yaml)
      Config.transform_config_with_templated_vars(config.config['env_template'], config.config["labels"])
      args = Docker.generate_label_arguments(config.config["labels"])
      assert_equal("--label app_name=#{Shellwords.escape("my_app's_di$course")}", args)
    end
  end
end

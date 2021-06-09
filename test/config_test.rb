# frozen_string_literal: true

require 'test_helper'
require 'tempfile'

module Pups
  class ConfigTest < MiniTest::Test
    def test_config_from_env
      ENV['HELLO'] = 'world'
      config = Config.new({})
      assert_equal('world', config.params['$ENV_HELLO'])
    end

    def test_env_param
      ENV['FOO'] = 'BAR'
      config = <<~YAML
        env:
          BAR: baz
          hello: WORLD
          one: 1
      YAML

      config = Config.new(YAML.safe_load(config))
      %w[BAR hello one].each { |e| ENV.delete(e) }
      assert_equal('BAR', config.params['$ENV_FOO'])
      assert_equal('baz', config.params['$ENV_BAR'])
      assert_equal('WORLD', config.params['$ENV_hello'])
      assert_equal('1', config.params['$ENV_one'])
    end

    def test_env_with_template
      ENV['FOO'] = 'BAR'
      config = <<~YAML
        env:
          greeting: "{{hello}}, {{planet}}!"
          one: 1
          other: "where are we on {{planet}}?"
        env_template:
          planet: pluto
          hello: hola
      YAML
      config_hash = YAML.safe_load(config)

      config = Config.new(config_hash)
      %w[greeting one other].each { |e| ENV.delete(e) }
      assert_equal('hola, pluto!', config.params['$ENV_greeting'])
      assert_equal('1', config.params['$ENV_one'])
      assert_equal('BAR', config.params['$ENV_FOO'])
      assert_equal('where are we on pluto?', config.params['$ENV_other'])
    end

    def test_env_with_ENV_templated_variable
      ENV['env_template_config'] = 'my_application'
      config = <<~YAML
        env:
          greeting: "{{hello}}, {{planet}}!"
          one: 1
          other: "building {{config}}"
        env_template:
          planet: pluto
          hello: hola
      YAML
      config_hash = YAML.safe_load(config)

      config = Config.new(config_hash)
      %w[greeting one other].each { |e| ENV.delete(e) }
      assert_equal('hola, pluto!', config.params['$ENV_greeting'])
      assert_equal('1', config.params['$ENV_one'])
      assert_equal('building my_application', config.params['$ENV_other'])
    end

    def test_integration
      f = Tempfile.new('test')
      f.close

      config = <<~YAML
        env:
          PLANET: world
        params:
          run: #{f.path}
          greeting: hello
        run:
          - exec: echo $greeting $PLANET >> #{f.path}
      YAML

      Config.new(YAML.safe_load(config)).run
      ENV.delete('PLANET')
      assert_equal('hello world', File.read(f.path).strip)
    ensure
      f.unlink
    end

    def test_hooks
      yaml = <<~YAML
        run:
          - exec: 1
          - exec:
              hook: middle
              cmd: 2
          - exec: 3
        hooks:
          after_middle:
            - exec: 2.1
          before_middle:
            - exec: 1.9
      YAML

      config = Config.load_config(yaml).config
      assert_equal({ 'exec' => 1.9 }, config['run'][1])
      assert_equal({ 'exec' => 2.1 }, config['run'][3])
    end

    def test_ignored_elements
      f = Tempfile.new('test')
      f.close

      yaml = <<~YAML
        env:
          PLANET: world
        params:
          greeting: hello
        run:
          - exec: 1
          - exec:
              hook: middle
              cmd: 2
          - exec: 3
          - exec: echo $greeting $PLANET >> #{f.path}
        hooks:
          after_middle:
            - exec: 2.1
          before_middle:
            - exec: 1.9
      YAML

      conf = Config.load_config(yaml, %w[hooks params])
      config = conf.config
      assert_equal({ 'exec' => 1 }, config['run'][0])
      assert_equal({ 'exec' => { 'hook' => 'middle', 'cmd' => 2 } }, config['run'][1])
      assert_equal({ 'exec' => 3 }, config['run'][2])
      assert_equal({ 'exec' => "echo $greeting $PLANET >> #{f.path}" }, config['run'][3])

      # $greet from params will be an empty var as it was ignored
      conf.run
      ENV.delete('PLANET')
      assert_equal('world', File.read(f.path).strip)
    end
  end
end

require 'test_helper'
require 'tempfile'

module Pups
  class ConfigTest < MiniTest::Test

    def test_config_from_env
      ENV["HELLO"] = "world"
      config = Config.new({})
      assert_equal("world", config.params["$ENV_HELLO"])
    end

    def test_env_param
      ENV["FOO"] = "BAR"
      config = <<YAML
env:
  BAR: baz
  hello: WORLD
  one: 1
YAML

      config = Config.new(YAML.load(config))
      assert_equal("BAR", config.params["$ENV_FOO"])
      assert_equal("baz", config.params["$ENV_BAR"])
      assert_equal("WORLD", config.params["$ENV_hello"])
      assert_equal("1", config.params["$ENV_one"])
    end

    def test_env_with_template
      ENV["FOO"] = "BAR"
      config = <<YAML
env:
  greeting: "{{hello}}, {{planet}}!"
  one: 1
  other: "where are we on {{planet}}?"
env_template:
  planet: pluto
  hello: hola
YAML
      config_hash = YAML.load(config)

      config = Config.new(config_hash)
      assert_equal("hola, pluto!", config.params["$ENV_greeting"])
      assert_equal("1", config.params["$ENV_one"])
      assert_equal("BAR", config.params["$ENV_FOO"])
      assert_equal("where are we on pluto?", config.params["$ENV_other"])
    end

    def test_env_with_ENV_templated_variable
      ENV["env_template_config"] = "my_application"
      config = <<YAML
env:
  greeting: "{{hello}}, {{planet}}!"
  one: 1
  other: "building {{config}}"
env_template:
  planet: pluto
  hello: hola
YAML
      config_hash = YAML.load(config)

      config = Config.new(config_hash)
      assert_equal("hola, pluto!", config.params["$ENV_greeting"])
      assert_equal("1", config.params["$ENV_one"])
      assert_equal("building my_application", config.params["$ENV_other"])
    end

    def test_integration

      f = Tempfile.new("test")
      f.close

      config = <<YAML
env:
  PLANET: world
params:
  run: #{f.path}
  greeting: hello
run:
  - exec: echo $greeting $PLANET >> #{f.path}
YAML

      Config.new(YAML.load(config)).run
      assert_equal("hello world", File.read(f.path).strip)

    ensure
      f.unlink
    end

    def test_hooks
      yaml = <<YAML
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
      assert_equal({ "exec" => 1.9 }, config["run"][1])
      assert_equal({ "exec" => 2.1 }, config["run"][3])


    end
  end
end


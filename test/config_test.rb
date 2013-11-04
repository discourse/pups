require 'test_helper'
require 'tempfile'

module Pups
  class ConfigTest < MiniTest::Test

    def test_integration

      f = Tempfile.new("test")
      f.close

      config = <<YAML
params:
  run: #{f.path}
run:
  - exec: echo hello world >> #{f.path}
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


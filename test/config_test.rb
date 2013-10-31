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
  end
end


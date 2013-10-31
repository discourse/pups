require 'test_helper'

module Pups

  class RunitTest < MiniTest::Test
    def test_can_append_env
      runit = Runit.new("foo")
      runit.env = {"FOO" => "bar"}
      runit.exec = "exec foo"

      assert(runit.run_script.include?("FOO=bar"))
    end

    def test_can_append_cd
      runit = Runit.new("foo")
      runit.cd = "/foo/bar"
      runit.exec = "exec foo"
      assert(runit.run_script.include?("cd /foo/bar"))
    end

  end
end

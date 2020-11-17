require "open3"

unless Gem.win_platform?
  class TestRPWIntegration < Minitest::Test
    COMMAND = "exe/rpw start"

    def test_setup
      matcher = nil
      Open3.popen3(COMMAND) do |stdin, stdout, stderr|
        stdin.close
        matcher = stdout.read
      end
      assert_match "Welcome to the Rails Performance Workshop", matcher
    end
  end
end

require "open3"

unless Gem.win_platform?
  class TestRPWIntegration < RPWTest
    COMMAND = "exe/rpw start"

    def setup
      delete_dotfile
      create_dotfile
    end

    def teardown
      delete_dotfile
    end

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

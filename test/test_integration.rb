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

    # with no rpw_info
    # setup creates rpw_info and directories, gitignore and README
    # all other commands rejected
    # setup creates info in home or PWD
    # with rpw_info
    # progress, lesson list show good output
    # key registration works/rejects bad input
    # download, show
    # download all
    # complete -> show -> complete -> show
    # next
    # progress setting
  end
end

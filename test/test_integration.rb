require "open3"

class TestRPWIntegration < Minitest::Test
  LICENSE_KEY = "this-is-a-key"
  ADMIN_KEY = "this-is-a-admin-key"

  def setup
  end

  def test_setup
    matcher = nil
    Open3.popen3("exe/rpw start") { |stdin, stdout, stderr|
      stdin.close
      matcher = stdout.read
    }
    assert_match "Welcome to the Rails Performance Workshop", matcher
  end
end

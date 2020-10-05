require "minitest/autorun"
require "rpw"

class TestGateway 
  def method_missing(*args)
    true
  end
end

class TestRPW < Minitest::Test 
  LICENSE_KEY = "this-is-a-key"
  ADMIN_KEY = "this-is-a-admin-key"

  def setup
    @client = RPW::Client.new
    if ENV["LIVE_SERVER"]
      def @client.gateway; @gateway ||= RPW::Gateway.new("localhost:3000"); end 
    else 
      def @client.gateway; @gateway ||= TestGateway.new; end
    end
    File.delete(RPW::Client::DOTFILE_NAME) if File.exist?(RPW::Client::DOTFILE_NAME)
  end

  def teardown
    File.delete(RPW::Client::DOTFILE_NAME) if File.exist?(RPW::Client::DOTFILE_NAME)
  end

  def test_setup_returns_provided_key
    assert_equal LICENSE_KEY, @client.setup(LICENSE_KEY)
  end

  def test_setup_creates_dotfile_with_key_idempotently
    @client.setup(LICENSE_KEY)
    @client.setup(LICENSE_KEY)

    assert_equal LICENSE_KEY, File.read(RPW::Client::DOTFILE_NAME)
  end

  def test_setup_dotfile_write_can_fail_and_raise
    File.stub :open, proc { raise } do
      assert_raises(RPW::Client::Error) { @client.setup(LICENSE_KEY) }
    end
  end 
end

require "minitest/autorun"

class TestGateway 
  def method_missing(*args)
    true
  end
end

class TestRPW < Minitest::Test
  def setup
    @client = RPW::Client.new
    def @client.gateway; @gateway ||= TestGateway.new; end
    File.delete(RPW::Client::DOTFILE_NAME) if File.exist?(RPW::Client::DOTFILE_NAME)
  end

  def teardown
    File.delete(RPW::Client::DOTFILE_NAME) if File.exist?(RPW::Client::DOTFILE_NAME)
  end

  def test_setup_returns_provided_key
    assert_equal "this-is-a-key", @client.setup("this-is-a-key")
  end

  def test_setup_creates_dotfile_with_key_idempotently
    @client.setup("this-is-a-key")
    @client.setup("this-is-a-key")

    assert_equal "this-is-a-key", File.read(RPW::Client::DOTFILE_NAME)
  end

  def test_setup_dotfile_write_can_fail_and_raise
    File.stub :open, proc { raise } do
      assert_raises(RPW::Client::Error) { @client.setup("this-is-a-key") }
    end
  end
end

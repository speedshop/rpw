require "minitest/autorun"
require "rpw"

class TestGateway
  def method_missing(*args)
    true
  end

  def respond_to_missing?(*args)
    true
  end
end

class TestRPW < Minitest::Test
  LICENSE_KEY = "this-is-a-key"
  ADMIN_KEY = "this-is-a-admin-key"

  def setup
    @client = RPW::Client.new
    if ENV["LIVE_SERVER"]
      def @client.gateway
        @gateway ||= RPW::Gateway.new("localhost:3000")
      end
    else
      def @client.gateway
        @gateway ||= TestGateway.new
      end
    end
    delete_dotfile
  end

  def teardown
    delete_dotfile
  end

  def test_setup_returns_provided_key
    assert_equal LICENSE_KEY, @client.setup(LICENSE_KEY)
  end

  def test_setup_creates_dotfile_with_key_idempotently
    @client.setup(LICENSE_KEY)
    @client.setup(LICENSE_KEY)

    assert_equal LICENSE_KEY, YAML.safe_load(File.read(RPW::ClientData.filestore_location))["key"]
  end

  def test_setup_dotfile_write_can_fail_and_raise
    File.stub :open, proc { raise } do
      assert_raises(RPW::Error) { @client.setup(LICENSE_KEY) }
    end
  end

  private

  def delete_dotfile
    [RPW::ClientData].each { |f| f.delete_filestore }
  end
end

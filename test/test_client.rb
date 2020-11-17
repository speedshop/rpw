require_relative "helper"

class TestRPW < Minitest::Test
  LICENSE_KEY = "this-is-a-key"
  ADMIN_KEY = "this-is-a-admin-key"

  def setup
    gateway = if ENV["LIVE_SERVER"]
      puts "Running against localhost server"
      RPW::Gateway.new("localhost:3000", LICENSE_KEY)
    else
      TestGateway.new
    end
    @client = RPW::Client.new(gateway)

    delete_dotfile
    create_dotfile
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
    RPW::ClientData.delete_filestore
  end

  def create_dotfile
    RPW::ClientData.create_in_pwd!
  end
end

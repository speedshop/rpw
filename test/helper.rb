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

# class TestClientData

class RPWTest < Minitest::Test
  def delete_dotfile
    RPW::ClientData.delete_filestore
  end

  def create_dotfile
    RPW::ClientData.create_in_pwd!
  end
end

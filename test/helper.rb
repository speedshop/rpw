require "minitest/autorun"
require "rpw"
require "rpw/cli"

class TestGateway
  def method_missing(*args)
    true
  end

  def respond_to_missing?(*args)
    true
  end
end
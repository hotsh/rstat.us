require_relative 'test_helper'

class RstatusTest < MiniTest::Unit::TestCase

  include Rack::Test::Methods

  def app() Rstatus end

  def test_hello_world
    get '/'
    assert last_response.ok?
    #assert_equal "Hello, world!", last_response.body
  end


end


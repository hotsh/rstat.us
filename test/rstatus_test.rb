require_relative 'test_helper'

class RstatusTest < MiniTest::Unit::TestCase

  include TestHelper

  def test_hello_world
    get '/'
    assert last_response.ok?
  end

  def test_login_with_twitter
    login
    assert_match /You're now logged in\./, last_response.body
  end

  def test_dashboard_page
    login
    assert_match /Update/, last_response.body
    assert_match /joepublic/, last_response.body
  end

end


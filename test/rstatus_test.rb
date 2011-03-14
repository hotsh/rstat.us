require_relative 'test_helper'

class RstatusTest < MiniTest::Unit::TestCase

  include TestHelper

  def test_hello_world
    skip
    get '/'
    assert last_response.ok?
  end

  def test_login_with_twitter
    skip "Figure out how sessions work."
    login
    assert_match /You're now logged in\./, session.last_response.body
  end

  def test_dashboard_page
    skip "Figure out how sessions work."
    login
    assert_match /Update/, session.last_response.body
    assert_match /#{current_user.username}/, session.last_response.body
  end

end


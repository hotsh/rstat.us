require_relative "test_helper"

class AuthorTest < MiniTest::Unit::TestCase

  include TestHelper

  def setup
    @author = Factory.build :author, :username => "james", :email => nil, :image_url => nil
  end

  def test_create_from_hash
    hash = {"user_info" => {"name" => "james", "nickname" => "jim", "urls" => {}} }
    assert Author.create_from_hash!(hash).is_a?(Author)
  end

  def test_url
    @author.remote_url = "some_url.com"
    assert_equal @author.remote_url, @author.url
  end

  def test_internal_avatar
    image_url = 'http://example.net/cool-avatar'
    @author.image_url = image_url
    assert_equal image_url, @author.avatar_url
  end

  def test_gravatar_avatar
    @author.email = "jamecook@gmail.com"
    assert_match 'http://gravatar.com/', @author.avatar_url
  end

  def test_fallback_avatar
    @author.email = nil
    assert_equal Author::DEFAULT_AVATAR, @author.avatar_url
  end
  
  def test_display_name_as_username
    @author.name = nil
    assert_equal @author.display_name, @author.username
  end
  
  def test_display_name_as_name
    @author.name = "Bender"
    assert_equal @author.display_name, "Bender"
  end
end

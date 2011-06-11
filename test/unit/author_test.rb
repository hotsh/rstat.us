require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../test_helper'

describe Author do

  include TestHelper

  before do
    @author = Factory.build :author, :username => "james", :email => nil, :image_url => nil
  end
  
  it "creates an author from a hash" do
    hash = {"user_info" => {"name" => "james", "nickname" => "jim", "urls" => {}} }
    assert Author.create_from_hash!(hash, "rstat.us").is_a?(Author)
  end

  it "returns remote_url as the url if set" do
    @author.remote_url = "some_url.com"
    assert_equal @author.remote_url, @author.url
  end

  describe "#avatar_url" do
    it "returns image_url as avatar_url if image_url is set" do
      image_url = 'http://example.net/cool-avatar'
      @author.image_url = image_url
      assert_equal image_url, @author.avatar_url
    end

    it "returns a gravatar if there is an email and image_url is not set" do
      @author.email = "jamecook@gmail.com"
      assert_match 'http://gravatar.com/', @author.avatar_url
    end

    it "uses the default avatar if neither image_url nor email is set" do
      @author.email = nil
      assert_equal Author::DEFAULT_AVATAR, @author.avatar_url
    end
  end

  describe "#display_name" do
    it "uses the username if name is not set" do
      @author.name = nil
      assert_equal @author.display_name, @author.username
    end

    it "uses the name if name is set" do
      @author.name = "Bender"
      assert_equal @author.display_name, "Bender"
    end
  end
end

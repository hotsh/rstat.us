require_relative '../test_helper'

describe Author do
  include TestHelper
  before do
    @author = Fabricate :author, :username => "james", :email => nil, :image_url => nil, :created_at => 3.days.ago
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
      assert_equal RstatUs::DEFAULT_AVATAR, @author.avatar_url
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

  describe "Author#search" do
    before do
      Fabricate :author, :username => "hipster", :email => nil, :image_url => nil
    end

    describe "search param" do
      it "uses param[:search] to filter by username" do
        @authors = Author.search(:search => "ame")
        assert_equal 1, @authors.size
        assert_equal @authors.first.username, "james"
      end

      it "returns none if search param is empty" do
        @authors = Author.search(:search => nil)
        assert_equal 0, @authors.size
      end

      it "returns none if no matches" do
        @authors = Author.search(:search => "blah")
        assert_equal 0, @authors.size
      end

      # TODO: it "sorts in no particular order?" is this what we want?
    end
  end
end

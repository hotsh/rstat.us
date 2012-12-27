require_relative '../test_helper'

describe Author do
  include TestHelper
  before do
    @author = Fabricate :author, :username => "james", :email => nil, :image_url => nil, :created_at => 3.days.ago
  end

  describe "#create_from_hash!" do
    it "creates an author from a hash" do
      hash = {"info" => {"name" => "james", "nickname" => "jim", "urls" => {}} }
      assert Author.create_from_hash!(hash, "rstat.us").is_a?(Author)
    end
  end

  describe "#new_from_session!" do
    it "has an image_url if the session has image" do
      session_hash = {:image => "foo.png"}
      a = Author.new_from_session!(session_hash, {}, "http://example.com")
      a.save!

      a.image_url.must_equal "foo.png"
    end
  end

  describe "#create_from_session!" do
    it "has an image_url if the session has image" do
      session_hash = {:image => "foo.png"}
      a = Author.create_from_session!(session_hash, {}, "http://example.com")

      a.image_url.must_equal "foo.png"
    end
  end

  describe "before_save callbacks" do
    describe "#normalize_domain" do
      it "stores the domain of a local user by normalizing the base url" do
        @author.domain = "http://example.com/"
        @author.save
        assert_equal @author.domain, "example.com"
      end
    end

    describe "#set_default_use_ssl" do
      it "sets the use_ssl flag to true when https is used to create the author" do
        author = Fabricate(:author, :username   => "james",
                                    :domain     => "https://example.com",
                                    :email      => nil,
                                    :image_url  => nil,
                                    :created_at => 3.days.ago)
        assert_equal author.use_ssl, true
      end

      it "sets the use_ssl flag to false when http is used to create the author" do
        author = Fabricate(:author, :username   => "james",
                                    :domain     => "http://example.com",
                                    :email      => nil,
                                    :image_url  => nil,
                                    :created_at => 3.days.ago)
        assert_equal author.use_ssl, false
      end
    end

    describe "#https_image_url" do
      it "ensures that image_url is always https" do
        @author.image_url = 'http://example.net/cool-avatar'
        @author.save!
        assert_equal 'https://example.net/cool-avatar', @author.image_url
      end

      it "ensures that https image_urls are untouched" do
        @author.image_url = 'https://example.net/cool-avatar'
        @author.save!
        assert_equal 'https://example.net/cool-avatar', @author.image_url
      end
    end

    describe "#modify_twitter_image_url_domain" do
      it "changes a twitter image URL to use the domain that matches the cert" do
        @author.image_url = 'https://a3.twimg.com/whatever'
        @author.save!
        assert_equal 'https://twimg0-a.akamaihd.net/whatever', @author.image_url
      end

      it "leaves other image urls alone" do
        @author.image_url = 'https://example.net/cool-avatar'
        @author.save!
        assert_equal 'https://example.net/cool-avatar', @author.image_url
      end
    end
  end

  describe "#url" do
    it "returns remote_url as the url if set" do
      @author.remote_url = "some_url.com"
      assert_equal @author.remote_url, @author.url
    end
  end

  describe "#fully_qualified_name" do
    it "returns simple name if a local user" do
      assert_equal "james", @author.fully_qualified_name
    end

    it "returns name with domain if a remote user" do
      @author.remote_url = "some_url.com"
      assert_equal "james@foo.example.com", @author.fully_qualified_name
    end
  end

  describe "#avatar_url" do
    it "returns image_url as avatar_url if image_url is set" do
      image_url = 'https://example.net/cool-avatar'
      @author.image_url = image_url
      assert_equal 'https://example.net/cool-avatar', @author.avatar_url
    end

    it "returns https gravatar if there is an email and image_url is not set" do
      @author.email = "jamecook@gmail.com"
      assert_match 'https://gravatar.com/', @author.avatar_url
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

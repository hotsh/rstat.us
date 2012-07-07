require_relative '../test_helper'

describe AuthorJsonDecorator do
  include TestHelper

  describe '#to_json, which implicitly calls as_json' do
    before do
      @author           = Fabricate(:author)
      @decorated_author = AuthorJsonDecorator.decorate(@author)
      @json             = @decorated_author.to_json
      @parsed_json      = JSON.parse(@json)
    end

    it "has the username" do
      @parsed_json["username"].must_equal(@author.username)
    end

    it "has the real name" do
      @parsed_json["name"].must_equal(@author.name)
    end

    it "has the website" do
      @parsed_json["website"].must_equal(@author.website)
    end

    it "has the bio" do
      @parsed_json["bio"].must_equal(@author.bio)
    end

    it "has the avatar" do
      @parsed_json["avatar"].must_equal(@author.avatar_url)
    end

    it "does not have any other attributes" do
      desired_keys   = ["username", "name", "website", "bio", "avatar"]
      remaining_keys = @parsed_json.keys - desired_keys
      assert remaining_keys.empty?
    end
  end
end

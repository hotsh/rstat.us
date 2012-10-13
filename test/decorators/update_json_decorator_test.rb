require_relative '../test_helper'

describe UpdateJsonDecorator do
  include TestHelper

  describe '#to_json, which implicitly calls as_json' do
    before do
      @update           = Fabricate.build(:update, :created_at => Time.now)
      @decorated_update = UpdateJsonDecorator.decorate(@update)
      @json             = @decorated_update.to_json
      @parsed_json      = JSON.parse(@json)
    end

    it "has the user who posted it" do
      @parsed_json["user"]["username"].must_equal(@update.author.username)
    end

    it "has the text of the update" do
      @parsed_json["text"].must_equal(@update.text)
    end

    it "has the date published" do
      json_time = Time.parse(@parsed_json["created_at"])

      json_time.to_i.must_equal(@update.created_at.to_i)
    end

    it "has the url to just that update" do
      @parsed_json["url"].must_equal(@update.url)
    end

    it "does not have any other attributes" do
      desired_keys   = ["user", "text", "created_at", "url"]
      remaining_keys = @parsed_json.keys - desired_keys
      assert remaining_keys.empty?
    end
  end
end

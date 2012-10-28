require_relative '../test_helper'

describe UpdateTwitterJsonDecorator do
  include TestHelper

  describe '#to_json, which implicitly calls as_json' do
    before do
      @update = Fabricate(:update)
      @decorated_update = UpdateTwitterJsonDecorator.decorate(@update)
    end

    describe "with user json" do
      it "passes whatever user json through" do
        @json        = @decorated_update.to_json(:user => "[\"one\"]")
        @parsed_json = JSON.parse(@json)

        @parsed_json["user"].must_equal("[\"one\"]")
      end
    end

    describe "without user json" do
      it "has the author's id and id_str but no other attributes" do
        @json        = @decorated_update.to_json
        @parsed_json = JSON.parse(@json)

        @parsed_json["user"]["id"].must_equal @update.author.id.to_s
        @parsed_json["user"]["id_str"].must_equal @update.author.id.to_s
        @parsed_json["user"].keys.sort.must_equal ["id", "id_str"].sort
      end
    end
  end
end
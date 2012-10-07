require_relative '../acceptance/acceptance_helper'

describe "ElasticSearch" do
  include AcceptanceHelper

  before do
    @update_text = "These aren't the droids you're looking for!"
    log_in_as_some_user
    VCR.use_cassette('publish_update') do
      fill_in 'update-textarea', :with => @update_text
      click_button :'update-button'
    end

    # Not using BONSAI_INDEX_URL in tests since that is only for
    # production on heroku.

    # All these tests should fail if running these without ElasticSearch
    # set up.
    assert ENV['ELASTICSEARCH_INDEX_URL'], "ElasticSearch is not configured. Please see the README for instructions."
  end

  it "gets a match for words in the update out of order" do
    search_for("for looking")

    assert_match @update_text, page.body
  end
end

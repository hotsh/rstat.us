require_relative '../test_helper'

describe TimeDecorator do
  include TestHelper

  before do
    @update = TimeDecorator.decorate(
                Fabricate.build(:update,
                  :created_at => Time.parse("2012-07-04 22:44:11 EDT")
                )
              )
  end

  describe "#abbr" do
    before do
      @abbr_html = Nokogiri::HTML.parse(@update.abbr)
    end

    it "has an abbr element with the correct attributes" do
      abbr = @abbr_html.at_xpath("//abbr")
      assert abbr
      abbr["class"].must_equal("timeago")
      abbr["title"].must_equal("2012-07-05T02:44:11Z")
    end

    it "has the ALPS date-time element in the correct format" do
      span = @abbr_html.at_xpath("//abbr/span")
      assert span
      span["class"].must_equal("date-time")
      span.text.must_equal("2012-07-05T02:44:11")
    end
  end

  describe "#permalink" do
    before do
      @permalink_html = Nokogiri::HTML.parse(@update.permalink)
    end

    it "has the time element with the correct attributes" do
      time_element = @permalink_html.at_xpath("//time")
      assert time_element
      time_element["class"].must_equal("published")
      time_element["pubdate"].must_equal("pubdate")
      time_element["datetime"].must_equal("2012-07-05T02:44:11Z")
    end

    it "has a link element for the permalink" do
      link = @permalink_html.at_xpath("//time/a")
      assert link
      link["class"].must_equal("timeago")
      link["href"].must_equal("/updates/#{@update.id}")
      link["rel"].must_equal("bookmark message")
      link["title"].must_equal("2012-07-05T02:44:11Z")
    end

    it "has the ALPS date-time element in the correct format" do
      span = @permalink_html.at_xpath("//time/a/span")
      assert span
      span["class"].must_equal("date-time")
      span.text.must_equal("2012-07-05T02:44:11")
    end
  end
end

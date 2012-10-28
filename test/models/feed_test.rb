require_relative '../test_helper'

describe Feed do
  include TestHelper

  def setup
    @feed = Fabricate(:feed)
  end

  describe ".create_and_populate!" do
    let(:feed_data)             { mock }
    let(:feed_data_url)         { mock }
    let(:feed_data_finger_data) { mock }
    let(:feed)                  { mock }

    before do
      feed_data.stubs(:url).returns(feed_data_url)
      Feed.stubs(:create).returns(feed)
      feed_data.stubs(:finger_data).returns(feed_data_finger_data)
      feed.stubs(:populate)
    end

    subject { Feed.create_and_populate!(feed_data) }

    it "gets the url from the feed data" do
      feed_data.expects(:url).returns(feed_data_url)
      subject
    end

    it "creates a feed from the feed data" do
      Feed.expects(:create).with(:remote_url => feed_data_url).returns(feed)
      subject
    end

    it "gets the finger_data from the feed data" do
      feed_data.expects(:finger_data).returns(feed_data_finger_data)
      subject
    end

    it "populates the feed with the finger data" do
      feed.expects(:populate).with(feed_data_finger_data)
      subject
    end
  end

  describe "#populate_entries" do
    describe "new update" do
      it "creates a new update" do
        updates_before = @feed.updates.length

        @feed.populate_entries([
          stub_everything(
            :url => "http://foo.com",
            :content => "I will take care of Yoshi"
          )
        ])

        @feed.updates.size.must_equal(updates_before + 1)
      end

      it "does nothing if the entry's URL is nil (just going to toss these until ostatus bug #4 is fixed)" do
        Fabricate(:update, :feed => @feed, :text => "Nacho update")
        updates_before = @feed.updates.length

        @feed.populate_entries([
          stub_everything(:url => nil, :content => "I do not smirk.")
        ])

        @feed.updates.size.must_equal(updates_before)
        @feed.updates.last.text.must_equal("Nacho update")
      end
    end

    describe "existing update" do
      it "does not create a new update if this update already exists" do
        u = Fabricate(:update, :feed => @feed, :remote_url => "http://a.b/1")
        update_text_before = u.text
        updates_before = @feed.updates.length

        @feed.populate_entries([
          stub_everything(:url => u.remote_url, :content => "I do not smirk.")
        ])

        @feed.updates.size.must_equal(updates_before)
        @feed.updates.last.text.must_equal(update_text_before)
      end

      it "does not change the existing update if the verb isn't update" do
        u = Fabricate(:update, :feed => @feed, :remote_url => "http://a.b/1")
        update_text_before = u.text
        updates_before = @feed.updates.length

        @feed.populate_entries([
          stub_everything(
            :url => u.remote_url,
            :content => "I do not smirk.",
            :activity => stub(:verb => "post")
          )
        ])

        @feed.updates.size.must_equal(updates_before)
        @feed.updates.last.text.must_equal(update_text_before)
      end

      it "changes the existing update if the verb is update" do
        u = Fabricate(:update, :feed => @feed, :remote_url => "http://a.b/1")
        update_text_before = u.text
        updates_before = @feed.updates.length

        @feed.populate_entries([
          stub_everything(
            :url => u.remote_url,
            :content => "I do not smirk.",
            :activity => stub(:verb => "update")
          )
        ])

        @feed.updates.size.must_equal(updates_before)
        @feed.updates.last.text.must_equal("I do not smirk.")
      end
    end
  end

  describe "#atom" do
    before do
      @later   = Fabricate(:update, :feed => @feed, :created_at => 1.day.ago)
      @earlier = Fabricate(:update, :feed => @feed, :created_at => 2.days.ago)
    end

    it "sorts updates in reverse chronological order by created_at" do
      atom = @feed.atom("http://example.com")
      xml = Nokogiri.XML(atom)
      entries = xml.xpath("//xmlns:entry")

      entries.first.at_xpath("xmlns:id").content.must_match(/#{@later.id}/)
      entries.last.at_xpath("xmlns:id").content.must_match(/#{@earlier.id}/)
    end

    it "limits the number of entries returned" do
      atom = @feed.atom("http://example.com", :num => 1)
      xml = Nokogiri.XML(atom)
      entries = xml.xpath("//xmlns:entry")

      entries.length.must_equal(1)
      entries.first.at_xpath("xmlns:id").content.must_match(/#{@later.id}/)
    end

    it "limits the entries returned by date" do
      atom = @feed.atom("http://example.com", :since => 36.hours.ago)
      xml = Nokogiri.XML(atom)
      entries = xml.xpath("//xmlns:entry")

      entries.length.must_equal(1)
      entries.first.at_xpath("xmlns:id").content.must_match(/#{@later.id}/)
    end
  end

  describe "#last_update" do
    it "returns the most recently created update" do

      later = Fabricate(:update, :feed => @feed, :created_at => 1.day.ago)
      earlier = Fabricate(:update, :feed => @feed, :created_at => 2.days.ago)

      @feed.last_update.must_equal(later)
    end
  end

  describe "#url" do
    it "does not end in .atom by default" do
      @feed.url.wont_match(/\.atom$/)
    end

    it "does end in .atom if we ask it to" do
      @feed.url(:format => :atom).must_match(/\.atom$/)
    end
  end
end

require_relative '../test_helper'

describe Feed do
  include TestHelper

  describe "#populate_entries" do
    describe "new update" do
      it "creates a new update" do
        f = Fabricate(:feed)
        updates_before = f.updates.length

        f.populate_entries([
          stub_everything(
            :url => "http://foo.com",
            :content => "I will take care of Yoshi"
          )
        ])

        f.updates.size.must_equal(updates_before + 1)
      end

      it "does nothing if the entry's URL is nil (just going to toss these until ostatus bug #4 is fixed)" do
        f = Fabricate(:feed)
        Fabricate(:update, :feed => f, :text => "Nacho update")
        updates_before = f.updates.length

        f.populate_entries([
          stub_everything(:url => nil, :content => "I do not smirk.")
        ])

        f.updates.size.must_equal(updates_before)
        f.updates.last.text.must_equal("Nacho update")
      end
    end

    describe "existing update" do
      it "does not create a new update if this update already exists" do
        f = Fabricate(:feed)
        u = Fabricate(:update, :feed => f, :remote_url => "http://a.b/1")
        update_text_before = u.text
        updates_before = f.updates.length

        f.populate_entries([
          stub_everything(:url => u.remote_url, :content => "I do not smirk.")
        ])

        f.updates.size.must_equal(updates_before)
        f.updates.last.text.must_equal(update_text_before)
      end

      it "does not change the existing update if the verb isn't update" do
        f = Fabricate(:feed)
        u = Fabricate(:update, :feed => f, :remote_url => "http://a.b/1")
        update_text_before = u.text
        updates_before = f.updates.length

        f.populate_entries([
          stub_everything(
            :url => u.remote_url,
            :content => "I do not smirk.",
            :activity => stub(:verb => "post")
          )
        ])

        f.updates.size.must_equal(updates_before)
        f.updates.last.text.must_equal(update_text_before)
      end

      it "changes the existing update if the verb is update" do
        f = Fabricate(:feed)
        u = Fabricate(:update, :feed => f, :remote_url => "http://a.b/1")
        update_text_before = u.text
        updates_before = f.updates.length

        f.populate_entries([
          stub_everything(
            :url => u.remote_url,
            :content => "I do not smirk.",
            :activity => stub(:verb => "update")
          )
        ])

        f.updates.size.must_equal(updates_before)
        f.updates.last.text.must_equal("I do not smirk.")
      end
    end
  end

  describe "#atom" do
    before do
      @f = Fabricate(:feed)
      @later = Fabricate(:update, :feed => @f, :created_at => 1.day.ago)
      @earlier = Fabricate(:update, :feed => @f, :created_at => 2.days.ago)
    end

    it "sorts updates in reverse chronological order by created_at" do
      atom = @f.atom("http://example.com")
      xml = Nokogiri.XML(atom)
      entries = xml.xpath("//xmlns:entry")

      entries.first.at_xpath("xmlns:id").content.must_match(/#{@later.id}/)
      entries.last.at_xpath("xmlns:id").content.must_match(/#{@earlier.id}/)
    end

    it "can limit the number of entries returned" do
      atom = @f.atom("http://example.com", :num => 1)
      xml = Nokogiri.XML(atom)
      entries = xml.xpath("//xmlns:entry")

      entries.length.must_equal(1)
      entries.first.at_xpath("xmlns:id").content.must_match(/#{@later.id}/)
    end

    it "can limit the entries returned by date" do
      atom = @f.atom("http://example.com", :since => 36.hours.ago)
      xml = Nokogiri.XML(atom)
      entries = xml.xpath("//xmlns:entry")

      entries.length.must_equal(1)
      entries.first.at_xpath("xmlns:id").content.must_match(/#{@later.id}/)
    end
  end

  describe "#last_update" do
    it "returns the most recently created update" do
      f = Fabricate(:feed)
      later = Fabricate(:update, :feed => f, :created_at => 1.day.ago)
      earlier = Fabricate(:update, :feed => f, :created_at => 2.days.ago)

      f.last_update.must_equal(later)
    end
  end
end

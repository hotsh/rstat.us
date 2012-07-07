require_relative '../test_helper'

describe AuthorDecorator do
  include TestHelper

  describe '#website_link' do
    before do
      @author = AuthorDecorator.decorate(Fabricate(:author))
    end

    it 'returns link to authors website' do
      @author.website_link.must_match('http://example.com')
    end

    it 'returns link to authors website when website is without http prefix' do
      @author.website = 'test.com'
      @author.website_link.must_match('http://test.com')
    end

    it "returns empty string if the author doesn't have a website" do
      @author.website = nil
      @author.website_link.must_equal("")
    end
  end

  describe "#absolute_website_url" do
    before do
      @author = AuthorDecorator.decorate(Fabricate(:author))
    end

    it 'returns url to authors website' do
      @author.absolute_website_url.must_equal('http://example.com')
    end

    it 'returns url to authors website when website is without http prefix' do
      @author.website = 'test.com'
      @author.absolute_website_url.must_equal('http://test.com')
    end

    it "returns nil if the author doesn't have a website" do
      @author.website = nil
      @author.absolute_website_url.must_equal(nil)
    end
  end
end

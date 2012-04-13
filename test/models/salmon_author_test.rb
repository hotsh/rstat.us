require 'minitest/autorun'
require 'mocha'
require 'ostatus'

require_relative '../../app/models/salmon_author'

describe "SalmonAuthor" do
  before do
    @uri = "http://google.com"
    @display_name = "Rumplestiltskin"
    @username = "rumply123"
    @bio = "I bet you can't guess my name."
    @avatar_url = "http://imgur.com/123"
    @email = "rumply@stiltskin.com"

    @poco = stub_everything(
              "poco",
              :id => 1,
              :display_name => @display_name,
              :note => @bio

            )

    @ostatus_author = OStatus::Author.new(
                        :name => @username,
                        :uri => @uri,
                        :portable_contacts => @poco,
                        :email => @email,
                        :links => [
                          Atom::Link.new(:rel  => "avatar",
                                         :type => "image/png",
                                         :href => @avatar_url
                                        )
                        ]
                      )
    @salmon_author = SalmonAuthor.new(@ostatus_author)
  end

  it "gets the author uri" do
    @salmon_author.uri.must_equal(@uri)
  end

  it "gets the author display name" do
    @salmon_author.name.must_equal(@display_name)
  end

  it "gets the author username" do
    @salmon_author.username.must_equal(@username)
  end

  it "gets the author bio" do
    @salmon_author.bio.must_equal(@bio)
  end

  it "gets the author avatar url" do
    @salmon_author.avatar_url.must_equal(@avatar_url)
  end

  it "gets the author email, if present" do
    @salmon_author.email.must_equal(@email)
  end

  it "returns nil if email is empty string" do
    @no_email = OStatus::Author.new(
                        :name => @username,
                        :uri => @uri,
                        :email => "",
                        :portable_contacts => @poco,
                        :links => [
                          Atom::Link.new(:rel  => "avatar",
                                         :type => "image/png",
                                         :href => @avatar_url
                                        )
                        ]
                      )
    @salmon_no_email = SalmonAuthor.new(@no_email)
    @salmon_no_email.email.must_equal(nil)
  end
end
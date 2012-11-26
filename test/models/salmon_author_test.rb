require 'minitest/autorun'
require 'mocha/setup'
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

  describe "#author_attributes" do
    it "returns a hash that can be used to populate or update Author attributes" do
      @salmon_author.author_attributes.must_equal({
        :name       => @display_name,
        :username   => @username,
        :remote_url => @uri,
        :domain     => @uri,
        :email      => @email,
        :bio        => @bio,
        :image_url  => @avatar_url
      })
    end
  end

  describe "==" do
    it "can tell that two SalmonAuthors are the same if their uris are" do
      @other_ostatus_author = OStatus::Author.new(
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
      @other_salmon_author = SalmonAuthor.new(@other_ostatus_author)
      assert @salmon_author == @other_salmon_author
    end

    it "can tell that two SalmonAuthors are different if their uris aren't" do
      @other_ostatus_author = OStatus::Author.new(
                          :name => @username,
                          :uri => "http://duckduckgo.com",
                          :portable_contacts => @poco,
                          :email => @email,
                          :links => [
                            Atom::Link.new(:rel  => "avatar",
                                           :type => "image/png",
                                           :href => @avatar_url
                                          )
                          ]
                        )
      @other_salmon_author = SalmonAuthor.new(@other_ostatus_author)
      refute @salmon_author == @other_salmon_author
    end

    it "can tell that a SalmonAuthor and an Author are the same if all their info is the same" do
      author = stub(
        :name       => @display_name,
        :username   => @username,
        :remote_url => @uri,
        :email      => @email,
        :bio        => @bio,
        :image_url  => @avatar_url
      )
      assert @salmon_author == author
    end

    it "can tell that a SalmonAuthor and an Author are different if the salmon author info would update the author" do
      author = stub(
        :name       => "not #{@display_name}",
        :username   => "not #{@username}",
        :remote_url => "not #{@uri}",
        :email      => "not #{@email}",
        :bio        => "not #{@bio}",
        :image_url  => "not #{@avatar_url}"
      )
      refute @salmon_author == author
    end
  end
end
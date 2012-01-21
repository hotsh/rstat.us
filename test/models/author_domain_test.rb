require_relative '../test_helper'

describe "Author domain storage" do
  include TestHelper

  def root_url # Stub for the root route
    "this_sites_domain.com"
  end

  it "stores a domain if passed in" do
    a = Author.create!(:domain => "some.domain")
    a.domain.must_equal("some.domain")
  end

  it "throws an error if the domain is not passed in" do
    lambda {
      a = Author.create!
    }.must_raise (MongoMapper::DocumentNotValid)
  end

  it "strips http://" do
    a = Author.create!(:domain => "http://some.domain")
    a.domain.must_equal("some.domain")
  end

  it "strips http://www." do
    a = Author.create!(:domain => "http://www.some.domain")
    a.domain.must_equal("some.domain")
  end

  it "strips www." do
    a = Author.create!(:domain => "www.some.domain")
    a.domain.must_equal("some.domain")
  end

  it "strips trailing /" do
    a = Author.create!(:domain => "some.domain/")
    a.domain.must_equal("some.domain")
  end

  # Who knows if these last few are possible or likely, but may as well, eh?
  it "strips trailing ?" do
    a = Author.create!(:domain => "some.domain?foo=bar")
    a.domain.must_equal("some.domain")
  end

  it "strips trailing #" do
    a = Author.create!(:domain => "some.domain#blah")
    a.domain.must_equal("some.domain")
  end

  it "strips trailing path" do
    a = Author.create!(:domain => "some.domain/one/two?three=four#five")
    a.domain.must_equal("some.domain")
  end
end
class SalmonInterpreter
  def initialize(body, params = {})
    raise(ArgumentError, "request body can't be empty") if !body || body.empty?

    @feed = SalmonInterpreter.find_feed(params[:feed_id])

    @salmon = SalmonInterpreter.parse(body)
    raise(ArgumentError, "can't parse salmon envelope") if @salmon.nil?

    @root_url = params[:root_url]
  end

  def interpret
    # We can ignore salmon for authors that have a local user account.
    return true if local_user?

    @author = find_or_initialize_author
    @author.check_public_key_lease

    raise RstatUs::InvalidSalmonMessage unless message_verified?

    # When we verify, we know (with some confidence at least) that the salmon
    # notification came from this author. We can then actually commit the
    # author if it is new.
    if @author.new?
      @author.save!
    end
  end

  # Isolating calls to external classes so we can stub these methods in test
  # and not have to load rails!

  def self.find_feed(id)
    # Using the bang version so we get a MongoMapper::DocumentNotFound exception
    # if this feed does not exist; the controller catches that exception
    # and renders a 404.
    Feed.find!(id)
  end

  def self.parse(body)
    OStatus::Salmon.from_xml body
  end

  private

  def find_or_initialize_author
    author = Author.first :remote_url => author_uri

    # This author is unknown to us, so let's create a new Author
    unless author
      author            = Author.new
      author.name       = author_name
      author.username   = author_username
      author.remote_url = author_uri
      author.domain     = author_uri
      author.email      = author_email
      author.bio        = author_bio
      author.image_url  = author_avatar_url

      # Retrieve the user xrd
      # XXX: Use the author uri to determine location of xrd
      remote_host = author.remote_url[/^.*?:\/\/(.*?)\//,1]
      webfinger   = "#{author.username}@#{remote_host}"
      acct        = Redfinger.finger(webfinger)

      # Retrieve the feed url for the user
      feed_url = acct.links.find { |l| l['rel'] == 'http://schemas.google.com/g/2010#updates-from' }

      # Retrieve the public key
      public_key = acct.links.find { |l| l['rel'].downcase == 'magic-public-key' }
      public_key = public_key.href[/^.*?,(.*)$/,1]
      author.public_key = public_key
      author.reset_key_lease

      # Salmon URL
      author.salmon_url = acct.links.find { |l| l['rel'].downcase == 'salmon' }
    end

    author
  end

  def message_verified?
    @salmon.verified?(@author.retrieve_public_key)
  end

  def local_user?
    author_uri.start_with?(@root_url)
  end

  def author_uri
    @salmon.entry.author.uri
  end

  def author_name
    @salmon.entry.author.portable_contacts.display_name
  end

  def author_username
    @salmon.entry.author.name
  end

  def author_bio
    @salmon.entry.author.portable_contacts.note
  end

  def author_avatar_url
    @salmon.entry.author.links.find_all{|l| l.rel.downcase == "avatar"}.first.href
  end

  def author_email
    email = @salmon.entry.author.email
    if email == ""
      return nil
    end
    email
  end
end
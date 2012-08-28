require_relative './salmon_author'

class SalmonInterpreter
  def initialize(body, params = {})
    raise(ArgumentError, "request body can't be empty") if !body || body.empty?

    @feed = SalmonInterpreter.find_feed(params[:feed_id])

    @salmon = SalmonInterpreter.parse(body)
    raise(ArgumentError, "can't parse salmon envelope") if @salmon.nil?

    @salmon_author = SalmonAuthor.new(@salmon.entry.author)
    @root_url = params[:root_url]
  end

  def interpret
    # We can ignore salmon for authors that have a local user account.
    return true if local_user?

    @author = find_or_initialize_author

    # If the author information cannot be found, salmon is invalid
    raise RstatUs::InvalidSalmonMessage if @author.nil?

    @author.check_public_key_lease

    # Verify the message against the author's key
    raise RstatUs::InvalidSalmonMessage unless message_verified?

    # When we verify, we know (with some confidence at least) that the salmon
    # notification came from this author. We can then actually commit the
    # author if it is new.
    if @author.new?
      @author.save!
    end

    process_activity
  end

  def process_activity
    case @salmon.entry.activity.verb
    when :post
      post
    when :follow
      follow
    when "http://ostatus.org/schema/1.0/unfollow"
      unfollow
    when "http://ostatus.org/schema/1.0/update-profile"
      update_profile
    end
  end

  # A new post that perhaps mentions or is in reply to our user
  def post
    # populate the feed
    @author.feed.populate_entries [@salmon.entry]

    # Determine reply-to context (if possible)
    thread = @salmon.entry.thr_in_reply_to
    if not thread.nil?
      update_url = thread.href
      # Local update url
      if update_url.start_with?(@root_url)
        # Retrieve update id
        update_id = update_url[/#{@root_url}\/updates\/(.*)$/,1]

        u = @author.feed.updates.first :remote_url => @salmon.entry.url
        u.referral_id = update_id
        u.save
      end
    end
  end

  # A notification that somebody is now following our user
  def follow
    user = @feed.author.user
    if user && !user.followed_by?(@author.feed)
      user.followed_by! @author.feed
    end
  end

  def unfollow
    user = @feed.author.user
    if user && user.followed_by?(@author.feed)
      user.unfollowed_by! @author.feed
    end
  end

  def update_profile
    # Don't bother updating the Author if it already has the same info
    # as the SalmonAuthor (for example if we just created it)
    if !(@salmon_author == @author)
      @author.update_attributes!(@salmon_author.author_attributes)
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
    author = Author.first :remote_url => @salmon_author.uri

    # This author is unknown to us, so let's create a new Author
    unless author
      author = Author.new(@salmon_author.author_attributes)

      # Retrieve the user xrd
      # XXX: Use the author uri to determine location of xrd
      remote_host = author.remote_url[/^.*?:\/\/(.*?)\//,1]
      webfinger   = "#{author.username}@#{remote_host}"

      begin
        acct = Redfinger.finger(webfinger)
      rescue Redfinger::ResourceNotFound
        # If there is any error in getting the xrd, then assume there isn't one
        # Without an xrd, an Author cannot be verified. The notification should
        #  not be trusted.
        return nil
      end

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
    @salmon_author.uri.start_with?(@root_url)
  end

end

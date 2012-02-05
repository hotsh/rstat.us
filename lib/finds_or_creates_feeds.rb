class FindsOrCreatesFeeds
  def self.find_or_create(subscribe_to)
    subscribe_to_feed = Feed.first(:id => subscribe_to)

    unless subscribe_to_feed
      # Allow for a variety of feed addresses
      case subscribe_to
      when /^feed:\/\//
        # SAFARI!!!!1 /me shakes his first at the sky
        feed_url = "http" + subscribe_to[4..-1]
      when /@/
        # XXX: ensure caching of finger lookup.
        redfinger_lookup = Redfinger.finger(subscribe_to)
        feed_url = redfinger_lookup.links.find { |l| l['rel'] == 'http://schemas.google.com/g/2010#updates-from' }.to_s
      else
        feed_url = subscribe_to
      end

      # See if we already have a local feed for this remote
      subscribe_to_feed = Feed.first(:remote_url => feed_url)

      unless subscribe_to_feed
        # create a feed
        subscribe_to_feed = Feed.create(:remote_url => feed_url)
        # Populate the Feed with Updates and Author from the remote site
        # Pass along the redfinger information to build the Author if available
        subscribe_to_feed.populate redfinger_lookup
      end
    end

    subscribe_to_feed
  end
end

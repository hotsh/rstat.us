class FindsOrCreatesFeeds
  def self.find_or_create(subscribe_to)
    feed = Feed.first(:id => subscribe_to)

    unless feed
      feed_data = ConvertsSubscriberToFeedData.get_feed_data(subscribe_to)

      # See if we already have a local feed for this remote
      feed = Feed.first(:remote_url => feed_data.url)

      unless feed
        feed = Feed.create_from_feed_data(feed_data)
      end
    end

    feed
  end
end

FeedData = Struct.new(:url, :xrd)

class ConvertsSubscriberToFeedData
  def self.get_feed_data(subscribe_to)
    feed_data = FeedData.new

    case subscribe_to
    when /^feed:\/\//
      # SAFARI!!!!1 /me shakes his first at the sky
      feed_data.url = "http" + subscribe_to[4..-1]
    when /@/
      # XXX: ensure caching of finger lookup.
      feed_data.xrd = Redfinger.finger(subscribe_to)
      feed_data.url= feed_data.xrd.links.find { |l| l['rel'] == 'http://schemas.google.com/g/2010#updates-from' }.to_s
    else
      feed_data.url = subscribe_to
    end

    feed_data
  end
end

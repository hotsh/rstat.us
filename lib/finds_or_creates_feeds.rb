require_relative 'finger'

class FindsOrCreatesFeeds
  def self.find_or_create(subscribe_to)
    feed = Feed.first(:id => subscribe_to)

    unless feed
      feed_data = ConvertsSubscriberToFeedData.get_feed_data(subscribe_to)
      feed = Feed.first(:remote_url => feed_data.url) || Feed.create_from_feed_data(feed_data)
    end

    feed
  end
end

FeedData = Struct.new(:url, :finger_data) 

class ConvertsSubscriberToFeedData
  def self.get_feed_data(subscriber_url)
    feed_data = FeedData.new

    case subscriber_url
    when /^feed:\/\//
      # SAFARI!!!!1 /me shakes his first at the sky
      feed_data.url = "http" + subscriber_url[4..-1]
    when /@/
      finger_data = QueriesWebFinger.query(subscriber_url)
      feed_data.url = finger_data.url
      feed_data.finger_data = finger_data
    else
      feed_data.url = subscriber_url
    end

    feed_data
  end
end

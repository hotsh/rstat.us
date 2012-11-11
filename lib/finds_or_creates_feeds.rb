require_relative 'converts_subscriber_to_feed_data'

class FindsOrCreatesFeeds
  def self.find_or_create(subscribe_to)
    feed = Feed.first(:id => subscribe_to)

    unless feed
      feed_data = ConvertsSubscriberToFeedData.new(subscribe_to).get_feed_data!
      feed = Feed.first(:remote_url => feed_data.url) || Feed.create_from_feed_data(feed_data)
    end

    feed
  end
end


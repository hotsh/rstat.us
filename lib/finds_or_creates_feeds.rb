require_relative 'converts_subscriber_to_feed_data'

class FindsOrCreatesFeeds

  def self.find_or_create(subscribe_to)
    feed = Feed.first(:id => subscribe_to)

    unless feed
      feed_data = ConvertsSubscriberToFeedData.new(subscribe_to).get_feed_data!
      feed = find_feed_by_remote_url(feed_data) || create_feed_from_feed_data(feed_data)
    end

    feed
  end

  private

  def self.find_feed_by_remote_url(feed_data)
    Feed.first(:remote_url => feed_data.url)
  end

  def self.create_feed_from_feed_data(feed_data)
    Feed.create_and_populate!(feed_data)
  end

end


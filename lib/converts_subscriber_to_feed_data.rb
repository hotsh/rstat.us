require_relative "queries_web_finger"
require_relative '../app/models/feed_data'

class ConvertsSubscriberToFeedData
  def self.get_feed_data(subscriber_url)
    feed_data = FeedData.new

    case subscriber_url
    when /^feed:\/\//
      # SAFARI!!!!1 /me shakes his first at the sky
      feed_data.url = "http" + subscriber_url[4..-1]
    when /@/
      begin
        finger_data = QueriesWebFinger.query(subscriber_url)
      rescue StandardError
        #
        # TODO Bubble up a better description of what went wrong.
        #
        #      We could see any one of the following here:
        #
        #      Redfinger::ResourceNotFound
        #      Nokogiri::SyntaxError        (Bad XML parsed by Redfinger)
        #      SocketError                  (DNS resolution or connect failure)
        #      ??? more ???
        #
        raise RstatUs::InvalidSubscribeTo
      end
      feed_data.url = finger_data.url
      feed_data.finger_data = finger_data
    when /^https?:\/\//
      feed_data.url = subscriber_url
    else
      raise RstatUs::InvalidSubscribeTo
    end

    feed_data
  end
end

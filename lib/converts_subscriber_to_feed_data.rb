require_relative "queries_web_finger"
require_relative '../app/models/feed_data'

class ConvertsSubscriberToFeedData

  def initialize(subscriber_url)
    @subscriber_url = subscriber_url
    @feed_data      = FeedData.new
  end

  def get_feed_data!
    case @subscriber_url
    when /^feed:\/\//
      convert_safari_scheme
    when /@/
      query_web_finger
    when /^https?:\/\//
      http_https_subscriber
    else
      raise RstatUs::InvalidSubscribeTo
    end

    @feed_data

  rescue StandardError
    # TODO Bubble up a better description of what went wrong.
    #
    #      We could see any one of the following here:
    #
    #      Redfinger::ResourceNotFound
    #      Nokogiri::SyntaxError        (Bad XML parsed by Redfinger)
    #      SocketError                  (DNS resolution or connect failure)
    #      ??? more ???
    raise RstatUs::InvalidSubscribeTo
  end

  private

  # replace Safari feed:// scheme with http://
  def convert_safari_scheme
    @feed_data.url = "http" + @subscriber_url[4..-1]
  end

  def query_web_finger
    finger_data            = QueriesWebFinger.query(@subscriber_url)
    @feed_data.url         = finger_data.url
    @feed_data.finger_data = finger_data
  end

  def http_https_subscriber
    @feed_data.url = @subscriber_url
  end

end

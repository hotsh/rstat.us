class SubscriberToFeedDataConverter

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
    @feed_data     = FingerService.new(@subscriber_url).finger!
  end

  def http_https_subscriber
    @feed_data.url = @subscriber_url
  end

end

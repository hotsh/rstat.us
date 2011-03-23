class Update
  require 'cgi'
  include MongoMapper::Document

  attr_accessor :oauth_secret, :oauth_token

  belongs_to :feed
  belongs_to :author

  key :text, String

  validates_length_of :text, :minimum => 1, :maximum => 140

  key :remote_url

  def url
    feed.local ? "/updates/#{id}" : url
  end

  def url=(url)
    self.remote_url = url
  end

  def to_html
    out = CGI.escapeHTML(text)
    out.gsub!(/@(\w+)/) do |match|
      if u = User.first(:username => /#{match[1..-1]}/i)
        "<a href='/users/#{u.username}'>#{match}</a>"
      else
        match
      end
    end
    out.gsub!(/(http:\/\/\S+[a-zA-Z\/])/, "<a href='\\1'>\\1</a>")
    out.gsub!(/#(\w+)/, "<a href='/hashtags/\\1'>#\\1</a>")
    out
  end

  def mentioned? search 
    matches = text.match(/^@#{search}/)
    matches.nil? ? false : matches.length > 0
  end

  after_create :tweet

  timestamps!

  def self.hashtag_search(tag)
    all(:text => /##{tag}/)
  end

  def self.hot_updates
    all(:limit => 6, :order => 'created_at desc')
  end

  protected

  def tweet
    return if ENV['RACK_ENV'] != "production"

    begin
      Twitter.configure do |config|
        config.consumer_key = Rstatus.settings.config["CONSUMER_KEY"]
        config.consumer_secret = Rstatus.settings.config["CONSUMER_SECRET"]
        config.oauth_token = oauth_token
        config.oauth_token_secret = oauth_secret
      end

      Twitter.update(text)
    rescue
    end
  end

end

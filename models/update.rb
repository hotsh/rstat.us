class Update
  require 'cgi'
  include MongoMapper::Document

  belongs_to :feed
  belongs_to :author

  key :text, String

  attr_accessor :oauth_token, :oauth_secret

  validates_length_of :text, :minimum => 1, :maximum => 140

  key :remote_url
  key :referral_id
  
  def referral
    Update.first(:id => referral_id)
  end

  def url
    feed.local? ? "/updates/#{id}" : remote_url
  end

  def url=(the_url)
    self.remote_url = the_url
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
    out.gsub!(/(http[s]?:\/\/\S+[a-zA-Z0-9\/])/, "<a href='\\1'>\\1</a>")
    out.gsub!(/#(\w+)/, "<a href='/hashtags/\\1'>#\\1</a>")
    out
  end

  def mentioned? search 
    matches = text.match(/^@#{search}/)
    matches.nil? ? false : matches.length > 0
  end

  after_create :tweet

  timestamps!

  def self.hashtag_search(tag, opts)
    popts = {
      :page => opts[:page],
      :per_page => opts[:per_page]
    }
    where(:text => /##{tag}/).order(['created_at', 'descending']).paginate(popts)
  end

  def self.hot_updates
    all(:limit => 6, :order => 'created_at desc')
  end

  protected

  def tweet
    return unless ENV['RACK_ENV'] == 'production'

    begin
      Twitter.configure do |config|
        config.consumer_key = ENV["CONSUMER_KEY"]
        config.consumer_secret = ENV["CONSUMER_SECRET"]
        config.oauth_token = oauth_token
        config.oauth_token_secret = oauth_secret
      end

      Twitter.update(text)
    rescue Exception => e
      #I should be shot for doing this.
    end
  end

end

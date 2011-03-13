class Update
  require 'cgi'
  include MongoMapper::Document

  belongs_to :user
  key :text, String

  validates_length_of :text, :maximum => 140

  def to_html
    out = CGI.escapeHTML(text)
    out.gsub!(/@(\w+)/, "<a href='/users/\\1'>@\\1</a>")
    out.gsub!(/(http:\/\/\S+[a-zA-Z\/])/, "<a href='\\1'>\\1</a>")
    out
  end

  after_create :tweet

  timestamps!

  protected

  def tweet
    Twitter.configure do |config|
      config.consumer_key = Rstatus.settings.config["CONSUMER_KEY"]
      config.consumer_secret = Rstatus.settings.config["CONSUMER_SECRET"]
      config.oauth_token = user.twitter_token
      config.oauth_token_secret = user.twitter_secret
    end

    Twitter.update(text)

  end

end

class Authorization
  include MongoMapper::Document
  
  belongs_to :user

  key :uid, Integer, :required => true
  key :provider, String, :required => true

  key :token, String, :required => true
  key :secret, String, :required => true

  validates_uniqueness_of :uid, :scope => :provider

  def self.find_from_hash(hsh)
    first :provider => hsh['provider'], :uid => hsh['uid'].to_i
  end

  def self.create_from_hash(hsh, user = nil)
    user ||= User.create_from_hash!(hsh)
    create!(:user => user, 
            :uid => hsh['uid'], 
            :provider => hsh['provider'],
            :token => hsh['credentials']['token'],
            :secret => hsh['credentials']['secret']
           )
  end

  timestamps!

end

class User
  include MongoMapper::Document
  many :authorizations, :dependant => :destroy

  key :name, String
  key :username, String
  key :email, String
  key :website, String
  key :bio, String
  key :twitter_image, String

  key :following_ids, Array
  many :following, :in => :following_ids, :class_name => 'User'

  key :followers_ids, Array
  many :followers, :in => :followers_ids, :class_name => 'User'

  def follow! followee
    following << followee
    save
    followee.followers << self
    followee.save
  end

  def unfollow! followee
    following_ids.delete(followee.id)
    save
    followee.followers_ids.delete(id)
    followee.save
  end

  def following? user 
    following.include? user
  end

  many :updates, :dependent => :destroy

  def self.create_from_hash!(hsh)
    create!(
      :name => hsh['user_info']['name'],
      :username => hsh['user_info']['nickname'],
      :website => hsh['user_info']['urls']['Website'],
      :bio => hsh['user_info']['description'],
      :twitter_image => hsh['user_info']['image']
    )
  end

  timestamps!

  def timeline
    following.map(&:updates).flatten
  end

  def twitter_token
    twitter_auth.token
  end

  def twitter_secret
    twitter_auth.secret
  end

  after_create :follow_yo_self

  private

  def twitter_auth
    Authorization.first :user_id => _id
  end

  def follow_yo_self
    following << self
    followers << self
    save
  end
end

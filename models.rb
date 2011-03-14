class Update
  require 'cgi'
  include MongoMapper::Document

  attr_accessor :oauth_secret, :oauth_token

  belongs_to :user
  key :text, String

  validates_length_of :text, :minimum => 1, :maximum => 140

  def to_html
    out = CGI.escapeHTML(text)
    out.gsub!(/@(\w+)/, "<a href='/users/\\1'>@\\1</a>")
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

    Twitter.configure do |config|
      config.consumer_key = Rstatus.settings.config["CONSUMER_KEY"]
      config.consumer_secret = Rstatus.settings.config["CONSUMER_SECRET"]
      config.oauth_token = oauth_token
      config.oauth_token_secret = oauth_secret
    end

    Twitter.update(text)

  end

end

class Authorization
  include MongoMapper::Document

  belongs_to :user

  key :uid, Integer, :required => true
  key :provider, String, :required => true

  validates_uniqueness_of :uid, :scope => :provider

  def self.find_from_hash(hsh)
    first :provider => hsh['provider'], :uid => hsh['uid'].to_i
  end

  def self.create_from_hash(hsh, user = nil)
    user ||= User.create_from_hash!(hsh)
    create!(:user => user, 
            :uid => hsh['uid'], 
            :provider => hsh['provider'],
           )
  end

  timestamps!

end

class User
  include MongoMapper::Document
  many :authorizations, :dependant => :destroy

  key :name, String
  key :username, String
  key :email, String, :required => true
  key :website, String
  key :bio, String
  key :twitter_image, String

  key :perishable_token, String

  after_create :reset_perishible_token 
  
  def reset_perishible_token
    require 'digest/md5'
    self.perishable_token = Digest::MD5.hexdigest(Time.now.to_s)
    save
  end

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

  alias :my_updates :updates

  def updates
    my_updates #.reject{|u| u.text =~ /^d /}
  end

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

  def at_replies
    Update.all(:text => /^@#{username} /)
  end

  def dm_replies
    Update.all(:text => /^d #{username} /)
  end

  key :status

  after_create :follow_yo_self

  attr_accessor :password
  key :hashed_password, String

  def password=(pass)
    @password = pass
    self.hashed_password = BCrypt::Password.create(@password, :cost => 10)
  end

  def self.authenticate(username, pass)
    user = User.first(:username => username)
    return nil if user.nil?
    return user if BCrypt::Password.new(user.hashed_password) == pass
    nil
  end

  private

  def follow_yo_self
    following << self
    followers << self
    save
  end
end

# This class handles sending emails. Everything related to it should go in
# here, that way it's just as easy as
# `Notifier.send_message_notification(me, you)` to send a message.
class Notifier 
  def self.send_signup_notification(recipient, token)
    Pony.mail(:to => recipient, 
              :subject => "Thanks for signing up for rstat.us!",
              :from => "steve+rstatus@steveklabnik.com",
              :body => render_haml_template("signup", {:token => token}),
              :via => :smtp, :via_options => Rstatus::PONY_VIA_OPTIONS)
  end

  private

  # This was kinda crazy to figure out. We have to make our own instantiation
  # of the Engine, and then set local variables. Crazy.
  def self.render_haml_template(template, opts)
    engine = Haml::Engine.new(File.open("views/notifier/#{template}.haml", "rb").read)
    engine.render(Object.new, opts)
  end
end


class Author
  include MongoMapper::Document
  
  key :username, String
  key :name, String
  key :email, String
  key :website, String
  key :bio, String
  key :image_url, String

  def self.create_from_hash!(hsh)
    puts hsh
    a = create!(
      :name => hsh['user_info']['name'],
      :username => hsh['user_info']['nickname'],
      :website => hsh['user_info']['urls']['Website'],
      :bio => hsh['user_info']['description'],
      :image_url => hsh['user_info']['image']
    )
    puts a.image_url
    a
  end

  def avatar_url
    if image_url.nil?
      if email.nil?
        # TODO: Use 'r' logo or something
        "http://gravatar.com/avatar/" + Digest::MD5.hexdigest("wilkie05@gmail.com") + "?s=48"
      else
        # Using gravatar
        "http://gravatar.com/avatar/" + Digest::MD5.hexdigest(email) + "?s=48"
      end
    else
      # Use the twitter image
      image_url
    end
  end

end

class Update
  require 'cgi'
  include MongoMapper::Document

  attr_accessor :oauth_secret, :oauth_token

  belongs_to :feed
  belongs_to :author

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
    # Could create an Author and THEN a User... maybe
    if user.nil?
      author = Author.create_from_hash!(hsh)
      user = User.create(:author => author,
                         :username => author.username
                        )
      puts user.author
      puts user.author.image_url
    end

    a = new(:user => user, 
            :uid => hsh['uid'], 
            :provider => hsh['provider']
           )

    unless a.save
      redirect "/"
    end

    a
  end

  timestamps!

end

class User
  require 'digest/md5'

  include MongoMapper::Document
  many :authorizations, :dependant => :destroy

  key :username, String, :required => true

  key :perishable_token, String

  after_create :reset_perishible_token 
  after_create :create_feed
  after_create :follow_yo_self

  belongs_to :author
  belongs_to :feed

  def reset_perishible_token
    self.perishable_token = Digest::MD5.hexdigest(Time.now.to_s)
    save
  end

  key :following_ids, Array
  many :following, :in => :following_ids, :class_name => 'Feed'

  key :followers_ids, Array
  many :followers, :in => :followers_ids, :class_name => 'Feed'

  def follow! followee
    following << followee
    save
    followee.followers << self
    followee.save
  end

  def unfollow! followee
  alias :my_updates :updates

    following_ids.delete(followee.id)
    save
    followee.followers_ids.delete(id)
    followee.save
  end

  def following? user 
    following.include? user
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

  def create_feed
    self.feed = Feed.create(
      :author => author
    )
    save
  end

  def follow_yo_self
    following << feed
    followers << feed
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

class Feed
  include MongoMapper::Document

  belongs_to :author
  many :updates

  def atom(base_uri)
    # Create the OStatus::PortableContacts object
    poco = OStatus::PortableContacts.new(:id => author.id,
                                         :display_name => author.name,
                                         :preferred_username => author.username)

    # Create the OStatus::Author object
    author = OStatus::Author.new(:name => author.username,
                                 :email => author.email,
                                 :uri => author.website,
                                 :portable_contacts => poco)

    # Gather entries as OStatus::Entry objects
    entries = updates.sort{|a, b| b.created_at <=> a.created_at}.map do |update|
      OStatus::Entry.new(:title => update.text,
                         :content => update.text,
                         :updated => update.updated_at,
                         :published => update.created_at,
                         :id => update.id,
                         :link => { :href => ("#{base_uri}/updates/#{update.id.to_s}")})
    end

    # Create a Feed representation which we can generate
    # the Atom feed and send out.
    feed = OStatus::Feed.from_data("#{base_uri}/feeds/#{id}",
                                   "#{author.username}'s Updates",
                                   "#{base_uri}/feeds/#{id}",
                                   author,
                                   entries,
                                   :hub => [{:href => ''}] )
    feed.atom
  end
end

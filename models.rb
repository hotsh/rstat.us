class Author
  include MongoMapper::Document
  
  key :username, String
  key :name, String
  key :email, String
  key :website, String
  key :bio, String
  key :image_url, String

  one :feed
  one :user

  def self.create_from_hash!(hsh)
    create!(
      :name => hsh['user_info']['name'],
      :username => hsh['user_info']['nickname'],
      :website => hsh['user_info']['urls']['Website'],
      :bio => hsh['user_info']['description'],
      :image_url => hsh['user_info']['image']
    )
  end

  def avatar_url
    if image_url.nil?
      if email.nil?
        # Using a default avatar
        "/images/avatar.png"
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

  # :url can also be used as a global identifier (and typically is)
  key :url, String
  key :text, String

  validates_length_of :text, :minimum => 1, :maximum => 140

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

  def self.create_from_hash(hsh, base_uri, user = nil)
    if user.nil?
      author = Author.create_from_hash!(hsh)
      user = User.create(:author => author,
                         :username => author.username
                        )
      user.finalize(base_uri)
    end

    a = new(:user => user, 
            :uid => hsh['uid'], 
            :provider => hsh['provider']
           )

    a.save
    a.errors.each{|e| puts e.inspect }
    a
  end

  timestamps!

end

class User
  require 'digest/md5'

  include MongoMapper::Document
  many :authorizations, :dependant => :destroy

  # Make the username required
  # However, this will break it when email authorization is used
  key :username, String, :unique => true
  key :perishable_token, String

  belongs_to :author
  belongs_to :feed

  def finalize(base_uri)
    create_feed(base_uri)
    follow_yo_self
    reset_perishable_token
  end

  def set_perishable_token
    self.perishable_token = Digest::MD5.hexdigest( rand.to_s )
    save
  end

  def reset_perishable_token
    self.perishable_token = nil
  end

  key :following_ids, Array
  many :following, :in => :following_ids, :class_name => 'Feed'

  key :followers_ids, Array
  many :followers, :in => :followers_ids, :class_name => 'Feed'

  # follow takes a url
  def follow! feed_url
    f = Feed.first(:url => feed_url)
    if f.nil?
      f = Feed.create(:url => feed_url,
                      :local => false)
      f.populate
    end

    following << f
    save

    if f.local
      followee = User.first(:author_id => f.author.id)
      followee.followers << self.feed
      followee.save
    end

    f
  end

  # unfollow takes a feed (since it is guaranteed to exist)
  def unfollow! followed_feed
    following_ids.delete(followed_feed.id)
    save
    if followed_feed.local
      followee = User.first(:author_id => followed_feed.author.id)
      followee.followers_ids.delete(self.feed.id)
      followee.save
    end
  end

  def following? feed_url
    f = Feed.first(:url => feed_url)
    if f == nil
      false
    else
      following.include? f
    end
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

  def create_feed(base_uri)
    f = Feed.create(
      :author => author,
      :local => true
    )
    f.generate_url(base_uri)
    f.save

    self.feed = f
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
  require 'osub'
  require 'opub'
  require 'nokogiri'

  include MongoMapper::Document

  # Feed url (and an indicator that it is local)
  key :url, String
  key :local, Boolean

  # OStatus subscriber information
  key :verify_token, String
  key :secret, String

  # For both pubs and subs, it needs to know
  # what hubs are communicating with it
  key :hubs, Array

  belongs_to :author
  many :updates
  one :user

  after_create :default_hubs

  def populate
    # TODO: More entropy would be nice
    self.verify_token = Digest::MD5.hexdigest(rand.to_s)
    self.secret = Digest::MD5.hexdigest(rand.to_s)

    f = OStatus::Feed.from_url(url)

    avatar_url = f.icon
    if avatar_url == nil
      avatar_url = f.logo
    end

    a = f.author

    self.author = Author.create(:name => a.name,
                                :username => a.name,
                                :email => a.email,
                                :image_url => avatar_url)

    self.hubs = f.hubs

    populate_entries(f.entries)

    save
  end

  def populate_entries(os_entries)
    os_entries.each do |entry|
      u = Update.first(:url => entry.url)
      if u.nil?
        u = Update.create(:author => self.author,
                          :created_at => entry.published,
                          :url => entry.url,
                          :updated_at => entry.updated)
        self.updates << u
        save
      end

      # Strip HTML
      u.text = Nokogiri::HTML::Document.parse(entry.content).text
      u.save
    end
  end

  def ping_hubs
    OPub::Publisher.new(url, hubs).ping_hubs
  end

  def update_entries(atom_xml, callback_url, signature)
    sub = OSub::Subscription.new(callback_url, self.url, self.secret)

    if sub.verify_content(atom_xml, signature)
      os_feed = OStatus::Feed.from_string(atom_xml)
      # TODO:
      # Update author if necessary

      # Update entries
      populate_entries(os_feed.entries)
    end
  end

  # Set default hubs
  def default_hubs
    self.hubs << "http://pubsubhubbub.appspot.com/publish"
    save
  end

  # Generates and stores the absolute local url
  def generate_url(base_uri)
    self.url = base_uri + "/feeds/#{id}.atom"
    save
  end

  def atom(base_uri)
    # Create the OStatus::PortableContacts object
    poco = OStatus::PortableContacts.new(:id => author.id,
                                         :display_name => author.name,
                                         :preferred_username => author.username)

    # Create the OStatus::Author object
    os_auth = OStatus::Author.new(:name => author.username,
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
                         :link => { :href => ("#{base_uri}updates/#{update.id.to_s}")})
    end

    # Create a Feed representation which we can generate
    # the Atom feed and send out.
    feed = OStatus::Feed.from_data("#{base_uri}feeds/#{id}.atom",
                                   :title => "#{author.username}'s Updates",
                                   :id => "#{base_uri}feeds/#{id}.atom",
                                   :author => os_auth,
                                   :entries => entries,
                                   :links => {
                                     :hub => [{:href => hubs.first}]
                                   })
    feed.atom
  end
end

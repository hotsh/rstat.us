class User
  require 'digest/md5'

  include MongoMapper::Document
  many :authorizations, :dependant => :destroy

  # Make the username required
  # However, this will break it when email authorization is used
  key :username, String, :unique => true
  key :perishable_token, String

  key :email, String, :unique => true

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

  def url
    feed.local ? "/users/#{feed.author.username}" : feed.author.url
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

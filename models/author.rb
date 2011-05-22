# The Author model represents someone who creates information that's
# shared via a feed. It is decoupled from a User, since we can also have
# remote authors, from feeds that originate from outside of our site.

class Author
  include MongoMapper::Document

  GRAVATAR               = "gravatar.com"
  DEFAULT_AVATAR         = "http://rstat.us/images/avatar.png"
  ENCODED_DEFAULT_AVATAR = URI.encode_www_form_component(DEFAULT_AVATAR)

  # We've got a bunch of data that gets stored in Author. And basically none
  # of it is val*idated right now. Fun. Then again, not all of it is neccesary.
  key :username,  String
  key :name,      String
  key :email,     String
  key :website,   String
  key :bio,       String
  key :image_url, String

  # as we said, an Author has a Feed that they're the... author of. And if
  # they're local, they also have a User, too.
  one :feed
  one :user

  # The url of their profile page
  key :remote_url, String

  # This takes results from an omniauth reponse and generates an author
  def self.create_from_hash!(hash)

    # Omniauth user information, as a hash
    user  = hash['user_info']

    # Grabs each of the important user details
    name       = user['name']
    username   = user['username']
    website    = user['urls']['Website']
    bio        = user['description']
    image      = user['image']
    remote     = user['url']

    # Creates an Author object with the details
    create!(
      name:       name,
      username:   username,
      website:    website,
      bio:        bio,
      image_url:  image,
      remote_url: remote
    )
  end

  # Returns a remote url, or the regular user url
  def url
    if remote_url.present?
      remote_url
    else
      "/users/#{username}"
    end
  end

  # Determine the avatar url and return it
  def avatar_url

    # If the user has a facebook or twitter image, return it
    if image_url.present?
      image_url

    # If the user has an email (Don't they have to?), look for a gravatar url.
    elsif email.present?
      gravatar_url

    # Otherwise return the default avatar
    else
      DEFAULT_AVATAR
    end
  end

  # Determine the display name from the username or name
  def display_name

    # If the user has a name, return it
    if name.present?
      name

    # Otherwise return the username
    else
      username
    end
  end

  # Return the gravatar url
  # Query described [here](http://en.gravatar.com/site/implement/images/#default-image).
  def gravatar_url
    email_digest = Digest::MD5.hexdigest email
    "http://#{GRAVATAR}/avatar/#{email_digest}?s=48&r=r&d=#{ENCODED_DEFAULT_AVATAR}"
  end
end

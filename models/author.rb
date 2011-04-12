# The Author model represents someone who creates information that's
# shared via a feed. It is decoupled from a User, since we can also have
# remote authors, from feeds that originate from outside of our site.

class Author
  include MongoMapper::Document

  DEFAULT_AVATAR = "http://rstat.us/images/avatar.png"
  ENCODED_DEFAULT_AVATAR = URI.encode_www_form_component(DEFAULT_AVATAR)

  GRAVATAR_HOST  = "gravatar.com"

  # We've got a bunch of data that gets stored in Author. And basically none
  # of it is validated right now. Fun. Then again, not all of it is neccesary.
  key :username, String
  key :name, String
  key :email, String
  key :website, String
  key :bio, String
  key :image_url, String

  # as we said, an Author has a Feed that they're the... author of. And if
  # they're local, they also have a User, too.
  one :feed
  one :user

  # The url of their profile page
  key :remote_url, String

  # This takes results from an omniauth reponse and generates an author
  def self.create_from_hash!(hsh)
    create!(
      :name => hsh['user_info']['name'],
      :username => hsh['user_info']['nickname'],
      :website => hsh['user_info']['urls']['Website'],
      :bio => hsh['user_info']['description'],
      :image_url => hsh['user_info']['image'],
      :remote_url => hsh['user_info']['url']
    )
  end

  def url
    return remote_url if remote_url
    "/users/#{username}"
  end

  # We've got a couple of options here. If they have some sort of image from
  # Facebook or Twitter, we use that, and if they don't, we go with Gravatar.
  # If none of that is around, then we show the DEFAULT_AVATAR
  def avatar_url
    return image_url      if image_url
    return DEFAULT_AVATAR if email.nil?

    gravatar_url
  end

  def display_name
    return username if name.nil? || name.empty?
    name
  end

  def gravatar_url
    "http://#{GRAVATAR_HOST}#{gravatar_path}"
  end

  # these query parameters are described [here](http://en.gravatar.com/site/implement/images/#default-image).
  def gravatar_path
    "/avatar/#{Digest::MD5.hexdigest(email)}?s=48&r=r&d=#{ENCODED_DEFAULT_AVATAR}"
  end
end

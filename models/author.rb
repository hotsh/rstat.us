class Author
  DEFAULT_AVATAR = "http://rstat.us/images/avatar.png"
  ENCODED_DEFAULT_AVATAR = URI.encode_www_form_component(DEFAULT_AVATAR)

  GRAVATAR_HOST  = "gravatar.com"
  
  include MongoMapper::Document
  
  key :username, String
  key :name, String
  key :email, String
  key :website, String
  key :bio, String
  key :image_url, String

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

  def avatar_url
    return image_url      if image_url
    return DEFAULT_AVATAR if email.nil?

    # if the gravatar doesn't exist, gravatar will use a default that we provide
    gravatar_url
  end

  def display_name
    return username if name.nil? || name.empty?
    name
  end

  def gravatar_url
    "http://#{GRAVATAR_HOST}#{gravatar_path}"
  end

  # these query parameters are described at:
  #   <http://en.gravatar.com/site/implement/images/#default-image>
  def gravatar_path
    "/avatar/#{Digest::MD5.hexdigest(email)}?s=48&r=r&d=#{ENCODED_DEFAULT_AVATAR}"
  end
end

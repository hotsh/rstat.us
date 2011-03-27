class Author
  GRAVATAR_HOST = "gravatar.com"
  
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
    if remote_url.nil?
      "/users/#{username}"
    else
      remote_url
    end
  end

  def avatar_url
    return image_url if image_url

    if email
      valid_gravatar? ? gravatar_url : "/images/avatar.png"
    else
      # Using a default avatar
      "/images/avatar.png"
    end
  end

  def valid_gravatar?
    Net::HTTP.start(GRAVATAR_HOST, 80) do |http|
      # Use HEAD instead of GET for SPEED!
      return http.head(gravatar_path).is_a?(Net::HTTPOK)
    end
  end

  def gravatar_url
    "http://#{GRAVATAR_HOST}#{gravatar_path}"
  end

  def gravatar_path
    "/avatar/#{Digest::MD5.hexdigest(email)}?s=48&r=r&d=404"
  end
end

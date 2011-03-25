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

  def self.gravatar_host
    "gravatar.com"
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
    return false unless use_gravatar?
    uri = URI.parse(gravatar_url)
    result = Net::HTTP.start(Author.gravatar_host, 80) do |http|
      res = http.head(uri.path + "?" +  uri.query ) # Use HEAD instead of GET for a faster response

      if res.class == Net::HTTPNotFound
        return false
      else
        return true
      end
    end
  end

  def gravatar_url
    path = "/avatar/" + Digest::MD5.hexdigest(email) + "?s=48&r=r&d=404"
    ["http://", Author.gravatar_host, path].join ""
  end

  private
  def use_gravatar?
    @use_gravatar || false # Useful for tests
  end
end



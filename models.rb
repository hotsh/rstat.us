class User
  include MongoMapper::Document
  many :authorizations

  key :name, String
  key :username, String
  key :email, String
  key :website, String
  key :bio, String
  key :twitter_image, String

  def self.create_from_hash!(hsh)
    create!(
      :name => hsh['user_info']['name'],
      :username => hsh['user_info']['nickname'],
      :website => hsh['user_info']['urls']['Website'],
      :bio => hsh['user_info']['description'],
      :twitter_image => hsh['user_info']['image']
    )
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
    create!(:user => user, :uid => hsh['uid'], :provider => hsh['provider'])
  end

end


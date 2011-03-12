class User
  include MongoMapper::Document
  many :authorizations

  def self.create_from_hash!(hsh)
    create(:name => hsh['user_info']['name'])
  end
end

class Authorization
  include MongoMapper::Document
  
  belongs_to :user

  key :uid, Integer, :required => true
  key :provider, String, :required => true

  validates_uniqueness_of :uid, :scope => :provider

  def self.find_from_hash(hsh)
    first :provider => hsh['provider'], :uid => hsh['uid']
  end

  def self.create_from_hash(hsh, user = nil)
    user ||= User.create_from_hash!(hsh)
    create!(:user => user, :uid => hsh['uid'], :provider => hsh['provider'])
  end

end


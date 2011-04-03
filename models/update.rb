class Update
  require 'cgi'
  include MongoMapper::Document
  include MongoMapperExt::Filter

  belongs_to :feed
  belongs_to :author

  key :text, String, :default => ""
  key :html, String
  key :tags, Array, :default => []
  key :language, String
  key :twitter, Boolean
  key :facebook, Boolean

  before_save :generate_html

  # store in authorization
  #attr_accessor :oauth_token, :oauth_secret

  validates_length_of :text, :minimum => 1, :maximum => 140
  before_create :get_tags
  before_create :get_language

  key :remote_url
  key :referral_id

  filterable_keys :text

  def referral
    Update.first(:id => referral_id)
  end

  def url
    feed.local? ? "/updates/#{id}" : remote_url
  end

  def url=(the_url)
    self.remote_url = the_url
  end

  def to_html
    self.html || generate_html
  end

  def mentioned?(username)
    matches = text.match(/@#{username}\b/)
    matches.nil? ? false : matches.length > 0
  end

  after_create :send_to_external_accounts

  timestamps!

  def self.hashtag_search(tag, opts)
    popts = {
      :page => opts[:page],
      :per_page => opts[:per_page]
    }
    where(:tags.in => [tag]).order(['created_at', 'descending']).paginate(popts)
  end

  def self.hot_updates
    all(:limit => 6, :order => 'created_at desc')
  end

  def get_tags
    self[:tags] = self.text.scan(/#([\w\-\.]*)/).flatten
  end

  def get_language
    self[:language] = self.text.language
  end

  # Return OStatus::Entry instance describing this Update
  def to_atom(base_uri)
    OStatus::Entry.new(:title => self.text,
                       :content => Atom::Content::Text.new(self.text),
                       :updated => self.updated_at,
                       :published => self.created_at,
                       :activity => OStatus::Activity.new(:object_type => :note),
                       :author => self.author.to_atom(base_uri),
                       :id => "#{base_uri}updates/#{self.id.to_s}",
                       :link => { :href => ("#{base_uri}updates/#{self.id.to_s}")})
  end

  protected

  # Generate and store the html
  def generate_html
    out = CGI.escapeHTML(text)

    # we let almost anything be in a username, except those that mess with urls.
    # but you can't end in a .:;, or !
    # also ignore container chars [] () "" '' {}
    # XXX: the _correct_ solution will be to use an email validator
    out.gsub!(/(^|[ \t\n\r\f"'\(\[{]+)@([^ \t\n\r\f&?=@%\/\#]*[^ \t\n\r\f&?=@%\/\#.!:;,"'\]}\)])/) do |match|
      if u = User.first(:username => /^#{$2}$/i)
        "#{$1}<a href='/users/#{u.username}'>@#{$2}</a>"
      else
        match
      end
    end
    out.gsub!(/(http[s]?:\/\/\S+[a-zA-Z0-9\/}])/, "<a href='\\1'>\\1</a>")
    out.gsub!(/(^|\s+)#(\w+)/) do |match|
      "#{$1}<a href='/hashtags/#{$2}'>##{$2}</a>"
    end
    self.html = out
  end

  # If a user has twitter or facebook enabled on their account and they checked
  # either twitter, facebook or both on update form, repost the update to
  # facebook or twitter. 
  def send_to_external_accounts
    return if ENV['RACK_ENV'] == 'development'

    # If there is no user we can't get to the oauth tokens, abort!
    if author.user
      # If the twitter flag is true and the user has a twitter account linked
      # send the update
      if self.twitter? && author.user.twitter?
        begin
          Twitter.configure do |config|
            config.consumer_key = ENV["CONSUMER_KEY"]
            config.consumer_secret = ENV["CONSUMER_SECRET"]
            config.oauth_token = author.user.twitter.oauth_token
            config.oauth_token_secret = author.user.twitter.oauth_secret
          end

          Twitter.update(text)
        rescue Exception => e
          #I should be shot for doing this.
        end
      end

      # If the facebook flag is true and the user has a facebook account linked
      # send the update
      if self.facebook? && author.user.facebook?
        begin
          user = FbGraph::User.me(author.user.facebook.oauth_token)
          user.feed!(:message => text)
        rescue Exception => e
          #I should be shot for doing this.
        end
      end
    end

  end

end

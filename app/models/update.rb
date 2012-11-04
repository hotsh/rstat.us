# encoding: utf-8
# An Update is a particular status message sent by one of our users.

class Update
  require 'cgi'
  include MongoMapper::Document

  if ENV['BONSAI_INDEX_URL'] || ENV['ELASTICSEARCH_INDEX_URL']
    include Tire::Model::Search
    include Tire::Model::Callbacks
    index_name ELASTICSEARCH_INDEX_NAME

    class << self
      alias :elastic_search :search
    end
  end

  def self.search(query, params = {})
    params[:from] ||= 0
    params[:size] ||= 20

    if query.blank?
      # Fallback to display all updates when query is blank
      page = params[:from] / params[:size] + 1
      per_page = params[:size]
      self.paginate(
        :page => page,
        :per_page => per_page,
        :order => :created_at.desc)
    elsif ENV['BONSAI_INDEX_URL'] || ENV['ELASTICSEARCH_INDEX_URL']
      # Tire adds a search method
      self.elastic_search(query, params)
    else
      # Fallback if elasticsearch is not enabled
      self.basic_search(query, params)
    end
  end

  # Determines what constitutes a username inside an update text
  USERNAME_REGULAR_EXPRESSION = /(^|[ \t\n\r\f"'\(\[{]+)@([^ \t\n\r\f&?=@%\/\#]*[^ \t\n\r\f&?=@%\/\#.!:;,"'\]}\)])(?:@([^ \t\n\r\f&?=@%\/\#]*[^ \t\n\r\f&?=@%\/\#.!:;,"'\]}\)]))?/

  # Updates are aggregated in Feeds
  belongs_to :feed
  key :feed_id, ObjectId

  # Updates are written by Authors
  belongs_to :author
  key :author_id, ObjectId
  validates_presence_of :author_id

  # The content of the update, unaltered, is stored here
  key :text, String, :default => ""
  validates_length_of :text, :minimum => 1, :maximum => 140
  validate :do_not_repeat_yourself, :on => :create

  # Mentions are stored in the following array
  key :mention_ids, Array
  many :mentions, :in => :mention_ids, :class_name => 'Author'
  before_save :get_mentions

  # The following are extra features and identifications for the update
  key :tags, Array, :default => []
  key :twitter, Boolean

  # For speed, we generate the html for the update lazily when it is rendered
  key :html, String


  # We also generate the tags upon editing the update
  before_save :get_tags

  # Updates have a remote url that globally identifies them
  key :remote_url, String

  # Reply and restate identifiers
  # Local Update id: (nil if remote)
  key :referral_id
  # Remote Update url: (nil if local)
  key :referral_url, String

  def to_indexed_json
    self.to_json
  end

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

  # These handle sending the update to other nodes and services
  after_create :send_to_remote_mentions
  after_create :send_to_external_accounts

  timestamps!

  def self.hot_updates
    all(:limit => 6, :order => 'created_at desc')
  end

  def get_tags
    self[:tags] = self.text.scan(/#([[:alpha:]\-\.]*)/).flatten
  end

  # Return OStatus::Entry instance describing this Update
  def to_atom(base_uri)
    links = []
    links << Atom::Link.new({ :href => ("#{base_uri}updates/#{self.id.to_s}")})

    mentions.each do |author|
      author_url = author.url
      if author_url.start_with?("/")
        author_url = "http://#{author.domain}/feeds/#{author.feed.id}"
      end

      links << Atom::Link.new({ :rel => 'ostatus:attention', :href => author_url })
      links << Atom::Link.new({ :rel => 'mentioned', :href => author_url })
    end

    OStatus::Entry.new(:title => self.text,
                       :content => Atom::Content::Html.new(self.to_html),
                       :updated => self.updated_at,
                       :published => self.created_at,
                       :activity => OStatus::Activity.new(:object_type => :note),
                       :author => self.author.to_atom,
                       :id => "#{base_uri}updates/#{self.id.to_s}",
                       :links => links)
  end

  def to_xml(base_uri)
    to_atom(base_uri).to_xml
  end

  def self.create_from_ostatus(entry, feed)
    u = new(:author     => feed.author,
            :created_at => entry.published,
            :remote_url => entry.url,
            :feed       => feed,
            :updated_at => entry.updated)

    u.sanitize_external_text(entry.content, entry.url)
    u.save
    u
  end

  def sanitize_external_text(entry_text, entry_url)
    # Strip HTML
    self.text = Nokogiri::HTML::Document.parse(entry_text).text

    # Truncate text
    truncation_necessary = self.text.length > 140
    if truncation_necessary
      self.text = self.text[0..138]
    end

    # Generate HTML
    if truncation_necessary
      self.html = "#{self.to_html}<a href='#{entry_url}'>\u2026</a>"
    end
  end

  protected

  def self.basic_search(query, params)
    leading_char = '\b'
    if query[0] == '#'
      leading_char = ''
    end
    # See explanation in searches_controller.rb about why we are
    # switching back to page and per_page when not using
    # ElasticSearch.
    page = params[:from] / params[:size] + 1
    per_page = params[:size]

    self.where(:text => /#{leading_char}#{Regexp.quote(query)}\b/i).
      paginate(
        :page => page,
        :per_page => per_page,
        :order => :created_at.desc)
  end

  def get_mentions
    self.mentions = []

    out = CGI.escapeHTML(text)

    out.gsub!(USERNAME_REGULAR_EXPRESSION) do |match|
      if $3 and a = Author.first(:username => /^#{$2}$/i, :domain => /^#{$3}$/i)
        self.mentions << a
      elsif not $3 and authors = Author.all(:username => /^#{$2}$/i)
        a = nil

        if authors.count == 1
          a = authors.first
        else
          # Disambiguate

          # Is it in update to this author?
          if in_reply_to = referral
            if not authors.index(in_reply_to.author).nil?
              a = in_reply_to.author
            end
          end

          # Is this update is generated by a local user,
          # look at who they are following
          if a.nil? and user = self.author.user
            authors.each do |author|
              if user.following_author?(author)
                a = author
              end
            end
          end
        end

        self.mentions << a unless a.nil?
      end
      match
    end

    self.mentions
  end

  # Generate and store the html
  def generate_html
    out = CGI.escapeHTML(text)

    # Replace any absolute addresses with a link
    # Note: Do this first! Otherwise it will add anchors inside anchors!
    out.gsub!(/(http[s]?:\/\/\S+[a-zA-Z0-9\/}])/, "<a href='\\1'>\\1</a>")

    # we let almost anything be in a username, except those that mess with urls.
    # but you can't end in a .:;, or !
    # also ignore container chars [] () "" '' {}
    # XXX: the _correct_ solution will be to use an email validator
    out.gsub!(USERNAME_REGULAR_EXPRESSION) do |match|
      if $3 and a = Author.first(:username => /^#{$2}$/i, :domain => /^#{$3}$/i)
        author_url = a.url
        if author_url.start_with?("/")
          author_url = "http://#{a.domain}#{author_url}"
        end
        "#{$1}<a href='#{author_url}'>@#{$2}@#{$3}</a>"
      elsif not $3 and a = Author.first(:username => /^#{$2}$/i)
        author_url = a.url
        if author_url.start_with?("/")
          author_url = "http://#{author.domain}#{author_url}"
        end
        "#{$1}<a href='#{author_url}'>@#{$2}</a>"
      else
        match
      end
    end

    out.gsub!( /(^|\s+)#(\p{Word}+)/ ) do |match|
      "#{$1}<a href='/search?search=%23#{$2}'>##{$2}</a>"
    end

    self.html = out
  end

  def send_to_remote_mentions
    # Only local users can do this
    if author.user
      # For each mention, if they are not following this user, send
      # this update to them as a salmon notification
      # XXX: allow for authors that we do not know (who do not have feeds)
      mentions.each do |mentioned_author|
        unless mentioned_author.domain == author.domain
          mentioned_feed = mentioned_author.feed
          unless author.user.followers.include? mentioned_feed
            author.user.delay.send_mention_notification id, mentioned_feed.id
          end
        end
      end
    end
  end

  # If a user has twitter enabled on their account and they checked
  # it on update form, repost the update to twitter
  def send_to_external_accounts
    return if ENV['RAILS_ENV'] == 'development'

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
    end

  end

  def do_not_repeat_yourself
    errors.add(:text, "You already posted this update.") if already_posted?
  end

  def already_posted?
    feed.last_update && feed.last_update.id != id && feed.last_update.text == text
  end
end

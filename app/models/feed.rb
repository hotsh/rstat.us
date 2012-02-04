# Feeds are pretty central to everything. They're a representation of a PuSH
# enabled Atom feed. Every user has a feed of their updates, we keep feeds
# for remote users that our users are subscribed to, and maybe even other
# things in the future, like hashtags.

class Feed
  # XXX: Are these even needed? Bundler should be require-ing them.
  require 'osub'
  require 'opub'
  require 'nokogiri'
  require 'atom'

  include MongoMapper::Document

  # Feed url (and an indicator that it is local if this is nil)
  key :remote_url, String

  # OStatus subscriber information
  key :verify_token, String
  key :secret, String

  # For both pubs and subs, it needs to know what hubs the feed is in
  # communication with in order to control pub/sub operations
  key :hubs, Array

  belongs_to :author
  key :author_id, ObjectId

  many :updates

  timestamps!

  after_create :default_hubs

  def self.find_or_create(subscribe_to)
    subscribe_to_feed = Feed.first(:id => subscribe_to)

    unless subscribe_to_feed
      # Allow for a variety of feed addresses
      case subscribe_to
      when /^feed:\/\//
        # SAFARI!!!!1 /me shakes his first at the sky
        feed_url = "http" + subscribe_to[4..-1]
      when /@/
        # XXX: ensure caching of finger lookup.
        redfinger_lookup = Redfinger.finger(subscribe_to)
        feed_url = redfinger_lookup.links.find { |l| l['rel'] == 'http://schemas.google.com/g/2010#updates-from' }.to_s
      else
        feed_url = subscribe_to
      end

      # See if we already have a local feed for this remote
      subscribe_to_feed = Feed.first(:remote_url => feed_url)

      unless subscribe_to_feed
        # create a feed
        subscribe_to_feed = Feed.create(:remote_url => feed_url)
        # Populate the Feed with Updates and Author from the remote site
        # Pass along the redfinger information to build the Author if available
        subscribe_to_feed.populate redfinger_lookup
      end
    end

    subscribe_to_feed
  end

   # This is because sometimes the mongomapper association returns nil
  # even though there is an author_id and the Author exists; see Issue #421
  def author
    Author.find(author_id)
  end

  def populate(xrd = nil)
    # TODO: More entropy would be nice
    self.verify_token = Digest::MD5.hexdigest(rand.to_s)
    self.secret = Digest::MD5.hexdigest(rand.to_s)

    ostatus_feed = OStatus::Feed.from_url(url)

    avatar_url = ostatus_feed.icon
    if avatar_url == nil
      avatar_url = ostatus_feed.logo
    end

    a = ostatus_feed.author

    self.author = Author.create(:name => a.portable_contacts.display_name,
                                :username => a.name,
                                :email => a.email,
                                :remote_url => a.uri,
                                :domain => a.uri,
                                :salmon_url => ostatus_feed.salmon,
                                :bio => a.portable_contacts.note,
                                :image_url => avatar_url)

    if xrd
      # Retrieve the public key
      public_key = xrd.links.find { |l| l['rel'].downcase == 'magic-public-key' }
      public_key = public_key.href[/^.*?,(.*)$/,1]
      self.author.public_key = public_key
      self.author.reset_key_lease

      # Salmon URL
      self.author.salmon_url = xrd.links.find { |l| l['rel'].downcase == 'salmon' }
      self.author.save
    end

    self.hubs = ostatus_feed.hubs

    save

    # Save the first 3 updates in our feed
    entries = ostatus_feed.entries

    if entries.length > 3
      entries = entries[0..2]
    end
    populate_entries(entries)

    save
  end

  def populate_entries(os_entries)
    os_entries.each do |entry|
      u = Update.first(:url => entry.url)
      new_update = false
      if u.nil?
        new_update = true
        u = Update.new(:author => self.author,
                       :created_at => entry.published,
                       :url => entry.url,
                       :feed => self,
                       :updated_at => entry.updated)
      end

      # Strip HTML
      u.text = Nokogiri::HTML::Document.parse(entry.content).text

      # Truncate text
      truncation_necessary = u.text.length > 140
      if truncation_necessary
        u.text = u.text[0..138]
      end

      # Generate HTML
      if truncation_necessary
        u.html = "#{u.to_html}<a href='#{entry.url}'>\u2026</a>"
      end

      # Commit
      u.save

      if new_update
        self.updates << u
      end

    end

    save
  end

  # Pings hub
  # needs absolute url for feed to give to hub for callback
  def ping_hubs
    feed_url = "#{url}.atom"
    OPub::Publisher.new(feed_url, hubs).ping_hubs
  end

  def local?
    remote_url.nil?
  end

  def url(atom_format = false)
    url = (remote_url.nil? && author) ? "http://#{author.domain}/feeds/#{id}" : remote_url
    url << ".atom" if atom_format
    url
  end

  def update_entries(atom_xml, callback_url, feed_url, signature)
    sub = OSub::Subscription.new(callback_url, feed_url, self.secret)

    if sub.verify_content(atom_xml, signature)
      os_feed = OStatus::Feed.from_string(atom_xml)
      # XXX: Update author if necessary

      populate_entries(os_feed.entries)
    end
  end

  def default_hubs
    self.hubs << "http://rstatus.superfeedr.com/"

    save
  end

  # create atom feed
  # need base_uri since urls outgoing should be absolute
  def atom(base_uri)
    # Create the OStatus::Author object
    os_auth = author.to_atom

    # Gather entries as OStatus::Entry objects
    entries = updates.to_a.sort{|a, b| b.created_at <=> a.created_at}.map do |update|
      update.to_atom(base_uri)
    end

    avatar_url_abs = author.avatar_url
    if avatar_url_abs.start_with?("/")
      avatar_url_abs = "#{base_uri}#{author.avatar_url[1..-1]}"
    end

    # Create a Feed representation which we can generate
    # the Atom feed and send out.
    feed = OStatus::Feed.from_data("#{base_uri}feeds/#{id}.atom",
                             :title => "#{author.username}'s Updates",
                             :logo => avatar_url_abs,
                             :id => "#{base_uri}feeds/#{id}.atom",
                             :author => os_auth,
                             :updated => updated_at,
                             :entries => entries,
                             :links => {
                               :hub => [{:href => hubs.first}],
                               :salmon => [{:href => "#{base_uri}feeds/#{id}/salmon"}],
                               :"http://salmon-protocol.org/ns/salmon-replies" =>
                                 [{:href => "#{base_uri}feeds/#{id}/salmon"}],
                               :"http://salmon-protocol.org/ns/salmon-mention" =>
                                 [{:href => "#{base_uri}feeds/#{id}/salmon"}]
                             })
    feed.atom
  end

  def last_update
    Update.where(:feed_id => id).order(['created_at', 'descending']).first
  end
end

class Rstatus
  require 'ostatus'

  # Salmon input
  post '/feeds/:id/salmon' do
    # XXX: change 'author' to a more suitable name (remote_author?)
    feed = Feed.first :id => params[:id]

    if feed.nil?
      status 404
      return
    end

    body = request.body.read
    salmon = OStatus::Salmon.from_xml body
    if salmon.nil?
      status 404
      return
    end

    # Verify data payload

    # Interpret data payload
    atom_entry = salmon.entry

    if atom_entry.author.uri.start_with?(url("/"))
      # Is a local user, we can ignore salmon
      status 200
      return
    end

    author = Author.first :remote_url => atom_entry.author.uri
    verify_author = false
    if author.nil?
      # This author is unknown to us, we should create a new author

      # Note that we need to save the author when we verify the source
      verify_author = true

      author = Author.new
      author.name = atom_entry.author.portable_contacts.display_name
      author.username = atom_entry.author.name
      author.remote_url = atom_entry.author.uri
      author.email = atom_entry.author.email
      author.email = nil if author.email == ""
      author.bio = atom_entry.author.portable_contacts.note
      avatar_url = atom_entry.author.links.find_all{|l| l.rel.downcase == "avatar"}.first.href
      author.image_url = avatar_url

      # Retrieve the user xrd
      remote_host = author.remote_url[/^.*?:\/\/(.*?)\//,1]
      webfinger = "#{author.username}@#{remote_host}"
      acct = Redfinger.finger(webfinger)

      # Retrieve the feed url for the user
      feed_url = acct.links.find { |l| l['rel'] == 'http://schemas.google.com/g/2010#updates-from' }

      # Retrieve the public key
      public_key = acct.links.find { |l| l['rel'] == 'magic-public-key' }
      public_key = public_key.href[/^.*?,(.*)$/,1]
      author.public_key = public_key
      author.reset_key_lease
    end

    # Check if the lease has expired
    if author.public_key_lease.nil? or author.public_key_lease < DateTime.now
      # Lease has expired, get the public key again

      # Retrieve the user xrd
      remote_host = author.remote_url[/^.*?:\/\/(.*?)\//,1]
      webfinger = "#{author.username}@#{remote_host}"
      acct = Redfinger.finger(webfinger)

      # Retrieve the public key
      public_key = acct.links.find { |l| l['rel'] == 'magic-public-key' }
      public_key = public_key.href[/^.*?,(.*)$/,1]
      author.public_key = public_key
      author.reset_key_lease

      unless verify_author
        author.save
      end
    end

    # Verify the feed
    verified = salmon.verified? author.public_key

    # When we verify, we know (with some confidence at least) that the salmon
    # notification came from this author.
    if not verified
      # Verification has failed
      status 404
      return
    end

    # Actually commit the new author if it is new and the message
    # has been verified as coming from that author.
    if verified and verify_author
      # Create a feed for our author
      author.feed = Feed.create(:author => author, 
                                :remote_url => feed_url)
      author.save
    end

    # Determine the action the notification is representing
    action = atom_entry.activity.verb
    user = feed.author.user

    # A new post that perhaps mentions or is in reply to our user
    if action == :post
      # populate the feed
      author.feed.populate_entries [atom_entry]

      # Determine reply-to context (if possible)
      thread = atom_entry.thr_in_reply_to
      if not thread.nil?
        update_url = thread.href
        if update_url.start_with?(url("/"))
          # Local update url
          # Retrieve update id
          update_id = update_url[/#{url("\/")}updates\/(.*)$/,1]
            u = author.feed.updates.first :remote_url => atom_entry.url
          u.referral_id = update_id
          u.save
        end
      end
    
    # A notification that somebody is now following our user
    elsif action == :follow
      if user
        if not user.following? author.feed.remote_url
          user.followed_by! author.feed
        end
      end

    # A notification that somebody has unfollowed our user
    elsif action == "http://ostatus.org/schema/1.0/unfollow"
      if user
        if user.followed_by? author.feed.remote_url
          user.unfollowed_by! author.feed
        end
      end
    end

    if development?
      puts "Salmon notification"
    end
  end
end

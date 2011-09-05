class SalmonController < ApplicationController
  def feeds
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
    puts atom_entry.to_xml

    if atom_entry.author.uri.start_with?(root_url)
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
      # XXX: Use the author uri to determine location of xrd
      remote_host = author.remote_url[/^.*?:\/\/(.*?)\//,1]
      webfinger = "#{author.username}@#{remote_host}"
      acct = Redfinger.finger(webfinger)

      # Retrieve the feed url for the user
      feed_url = acct.links.find { |l| l['rel'] == 'http://schemas.google.com/g/2010#updates-from' }

      # Retrieve the public key
      public_key = acct.links.find { |l| l['rel'].downcase == 'magic-public-key' }
      public_key = public_key.href[/^.*?,(.*)$/,1]
      author.public_key = public_key
      author.reset_key_lease

      # Salmon URL
      author.salmon_url = acct.links.find { |l| l['rel'].downcase == 'salmon' }
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
    verified = salmon.verified? author.retrieve_public_key

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
        if update_url.start_with?(root_url)
          # Local update url
          # Retrieve update id
          update_id = update_url[/#{root_url}\/updates\/(.*)$/,1]
            u = author.feed.updates.first :remote_url => atom_entry.url
          u.referral_id = update_id
          u.save
        end
      end

    # A notification that somebody is now following our user
    elsif action == :follow
      if user
        if not user.following_author? author
          user.followed_by! author.feed
        end
      end

    # A notification that somebody has unfollowed our user
    elsif action == "http://ostatus.org/schema/1.0/unfollow"
      if user
        if user.followed_by? author.feed
          user.unfollowed_by! author.feed
        end
      end

    # A profile update
    elsif action == "http://ostatus.org/schema/1.0/update-profile"
      if not verify_author
        author.name = atom_entry.author.portable_contacts.display_name
        author.username = atom_entry.author.name
        author.remote_url = atom_entry.author.uri
        author.email = atom_entry.author.email
        author.email = nil if author.email == ""
        author.bio = atom_entry.author.portable_contacts.note
        avatar_url = atom_entry.author.links.find_all{|l| l.rel.downcase == "avatar"}.first.href
        author.image_url = avatar_url
        author.save
      end
    end

    if development?
      puts "Salmon notification"
    end
  end
end

class SalmonController < ApplicationController
  def feeds
    SalmonInterpreter.new(
      request.body.read,
      {
        :feed_id  => params[:id],
        :root_url => root_url
      }
    ).interpret
    status 200
    return
  rescue MongoMapper::DocumentNotFound, ArgumentError, RstatUs::InvalidSalmonMessage
    render :file => "#{Rails.root}/public/404.html", :status => 404
    return
  end

    # # Determine the action the notification is representing
    # action = atom_entry.activity.verb
    # user = feed.author.user
    #
    # # A new post that perhaps mentions or is in reply to our user
    # if action == :post
    #   # populate the feed
    #   author.feed.populate_entries [atom_entry]
    #
    #   # Determine reply-to context (if possible)
    #   thread = atom_entry.thr_in_reply_to
    #   if not thread.nil?
    #     update_url = thread.href
    #     if update_url.start_with?(root_url)
    #       # Local update url
    #       # Retrieve update id
    #       update_id = update_url[/#{root_url}\/updates\/(.*)$/,1]
    #         u = author.feed.updates.first :remote_url => atom_entry.url
    #       u.referral_id = update_id
    #       u.save
    #     end
    #   end
    #
    # # A notification that somebody is now following our user
    # elsif action == :follow
    #   if user
    #     if not user.following_author? author
    #       user.followed_by! author.feed
    #     end
    #   end
    #
    # # A notification that somebody has unfollowed our user
    # elsif action == "http://ostatus.org/schema/1.0/unfollow"
    #   if user
    #     if user.followed_by? author.feed
    #       user.unfollowed_by! author.feed
    #     end
    #   end
    #
    # # A profile update
    # elsif action == "http://ostatus.org/schema/1.0/update-profile"
    #   if not verify_author
    #     author.name = atom_entry.author.portable_contacts.display_name
    #     author.username = atom_entry.author.name
    #     author.remote_url = atom_entry.author.uri
    #     author.email = atom_entry.author.email
    #     author.email = nil if author.email == ""
    #     author.bio = atom_entry.author.portable_contacts.note
    #     avatar_url = atom_entry.author.links.find_all{|l| l.rel.downcase == "avatar"}.first.href
    #     author.image_url = avatar_url
    #     author.save
    #   end
    # end
    #
    # if Rails.env.development?
    #   puts "Salmon notification"
    # end
  # end
end

class WebfingerController < ApplicationController
  # Webfinger base xml, describes how to find user xrds
  def host_meta
    @base_url = root_url
    @hostname = request.host

    render "xml/webfinger/host-meta", :layout => false, :content_type => "application/xrd+xml"
  end

  # User xrd generation
  def xrd
    # webfinger likes to give fully qualified names
    # For example: "acct:wilkie@rstat.us"

    # This is rather redundant, but what can you do?
    # here we strip off the extra foo:
    username = params[:username][/^([^@\:]+\:)?([^@\:]*?)(@[^@\:]+)?$/, 2] || params[:username]

    @user = User.first :username => /^#{username}$/i

    if @user
      @base_url = root_url
      render "xml/webfinger/xrd", :layout => false, :content_type => "application/xrd+xml"
    else
      render :file => "#{Rails.root}/public/404.html", :status => 404
    end
  end
end

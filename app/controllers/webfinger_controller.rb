class WebfingerController < ApplicationController
  # [Webfinger](http://hueniverse.com/webfinger/) base xml, describes how to
  # find a user's Extensible Resource Descriptor (xrd)
  def host_meta
    @base_url = root_url
    @hostname = request.host

    render "xml/webfinger/host-meta", :layout => false, :content_type => "application/xrd+xml"
  end

  # User xrd generation
  def xrd
    @user = Webfinger.find_user(params[:username])

    if @user
      @base_url = root_url
      render "xml/webfinger/xrd", :layout => false, :content_type => "application/xrd+xml"
    else
      render :file => "#{Rails.root}/public/404", :status => 404
    end
  end
end

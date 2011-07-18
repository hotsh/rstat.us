class Rstatus

  # webfinger integration

  # Webfinger base xml, describes how to find user xrds
  get '/.well-known/host-meta' do
    @base_url = url("/")
    @hostname = request.host

    content_type "application/xrd+xml"
    haml :"xml/webfinger/host-meta", :layout => false
  end

  # User xrd generation
  get "/users/:username/xrd.xml" do
    # webfinger likes to give fully qualified names
    # For example: "acct:wilkie@rstat.us" 

    # This is rather redundant, but what can you do?
    # here we strip off the extra foo:
    username = params[:username][/^.*?\:(.*?)@/, 1] || params[:username]

    @user = User.first :username => /^#{username}$/i
    @base_url = url("/")

    content_type "application/xrd+xml"
    haml :"xml/webfinger/xrd", :layout => false
  end

end

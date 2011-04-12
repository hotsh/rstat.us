# This simple controller generates routes for all of our 'static' pages. We 
# still run them through haml, because writing HTML totally sucks, so routes
# must be made. We can't just dump them in `public/`.

# XXX: Add explicit caching headers to all of these.
class Rstatus
  get "/open_source" do
    haml :opensource
  end

  get "/follow" do
    haml :external_subscription
  end

  get "/contact" do
    haml :contact
  end

  get "/help" do
    haml :help
  end
end

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
end

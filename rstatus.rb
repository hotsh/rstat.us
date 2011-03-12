require 'sinatra/base'

require 'omniauth'

class Rstatus < Sinatra::Base

  configure do
    enable :sessions
  end

  use OmniAuth::Builder do
    cfg = YAML.load_file("config.yml")[ENV['RACK_ENV']]
    provider :twitter, cfg["CONSUMER_KEY"], cfg["CONSUMER_SECRET"]
  end

 get '/' do
    <<-HTML
    <a href='/auth/twitter'>Sign in with Twitter</a>
    HTML
  end

  get '/auth/twitter/callback' do
    #request.env['omniauth.auth'].to_s
    "You're now logged in."
  end

end 


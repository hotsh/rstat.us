class Rstatus
  # The `PONY_VIA_OPTIONS` hash is used to configure `pony`. Basically, we only
  # want to actually send mail if we're in the production environment. So we set
  # the hash to just be `{}`, except when we want to send mail.
  configure :test do
    PONY_VIA_OPTIONS = {}
  end

  configure :development do
    PONY_VIA_OPTIONS = {}
  end

  configure :production do
    Compass.configuration do |config|
      config.output_style = :compressed
    end
  end


  # We're using [SendGrid](http://sendgrid.com/) to send our emails. It's really
  # easy; the Heroku addon sets us up with environment variables with all of the
  # configuration options that we need.
  configure :production do
    PONY_VIA_OPTIONS =  {
      :address        => "smtp.sendgrid.net",
      :port           => "25",
      :authentication => :plain,
      :user_name      => ENV['SENDGRID_USERNAME'],
      :password       => ENV['SENDGRID_PASSWORD'],
      :domain         => ENV['SENDGRID_DOMAIN']
    }
  end

  # We need a secret for our sessions. This is set via an environment variable so
  # that we don't have to give it away in the source code. Heroku makes it really
  # easy to keep environment variables set up, so this ends up being pretty nice.
  # This also has to be included before rack-flash, or it blows up.
  use Rack::Session::Cookie, :secret => ENV['COOKIE_SECRET']

  # We're using rack-timeout to ensure that our dynos don't get starved by renegade
  # processes.
  use Rack::Timeout
  Rack::Timeout.timeout = 10

  set :root, File.dirname(__FILE__)
  set :haml, :escape_html => true

  # This method enables the ability for our forms to use the _method hack for 
  # actual RESTful stuff.
  set :method_override, true

  # If you've used Rails' flash messages, you know how convenient they are.
  # rack-flash lets us use them.
  use Rack::Flash

  configure do
    if ENV['MONGOHQ_URL']
      MongoMapper.config = {ENV['RACK_ENV'] => {'uri' => ENV['MONGOHQ_URL']}}
      MongoMapper.database = ENV['MONGOHQ_DATABASE']
      MongoMapper.connect("production")
    else
      MongoMapper.connection = Mongo::Connection.new('localhost')
      MongoMapper.database = "rstatus-#{settings.environment}"
    end

    # configure compass
    Compass.configuration do |config|
      config.project_path = File.dirname(__FILE__)
      config.sass_options = {:cache_location => "./tmp/sass-cache"}
    end
    MongoMapperExt.init

    # now that we've connected to the db, let's load our models.
    require_relative 'models/all'
  end

  helpers Sinatra::UserHelper
  helpers Sinatra::ContentFor

  helpers do
    [:development, :production, :test].each do |environment|
      define_method "#{environment.to_s}?" do
        return settings.environment == environment
      end
    end
  end

  use OmniAuth::Builder do
    provider :twitter, ENV["CONSUMER_KEY"], ENV["CONSUMER_SECRET"]
    provider :facebook, ENV["APP_ID"], ENV["APP_SECRET"], {:scope => 'publish_stream,offline_access,email'}
  end
end

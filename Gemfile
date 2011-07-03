source "http://rubygems.org"

# this gem has to come before any that use require_relative
gem "require_relative", :git => 'git://github.com/bct/require_relative.git', :platforms => :ruby_18

gem "omniauth"
gem "sinatra", :require => "sinatra/base"
gem "mongo_mapper"
gem "mongomapper_ext"
gem "bson_ext"
gem "i18n"
gem "haml"
gem "rake", "=0.8.7"
gem "rack", "=1.2.2"
gem "rack-flash"
gem "rack-timeout"
gem "system_timer", :platforms => :ruby_18
gem "time-lord"
gem "sinatra-content-for", :require => "sinatra/content_for"
gem "sinatra-redirect-with-flash", :require => "sinatra/redirect_with_flash"
gem "twitter"
gem "fb_graph"
gem "pony"
gem "bcrypt-ruby", :require => "bcrypt"
gem "rdiscount"
gem "backports", :platforms => :ruby_18
gem "ostatus", "> 0.0.9"
gem "osub", "> 0.0.6"
gem "opub"
gem "redfinger"
gem "nokogiri", "= 1.4.4"
gem "newrelic_rpm"
gem "whatlanguage"
gem "ruby-stemmer"
gem "sass"
gem "compass"
gem "tzinfo"
gem "rsa"
gem "exceptional"
gem "sprockets", "2.0.0.beta.10"
gem "rack-mount", :require => "rack/mount"
gem "uglifier"

# background job queue
gem "delayed_job", :git => "git://github.com/collectiveidea/delayed_job.git", :tag => "v2.1.4"
gem "delayed_job_mongo_mapper", :git => "git://github.com/earbits/delayed_job_mongo_mapper.git"
gem "whenever"

group :development, :test do
  gem "minitest", :platforms => :ruby_18
  gem 'coffee-script'
  gem 'rack-test'
  gem "database_cleaner"
  gem "factory_girl"
  gem "capybara"
  gem "rocco"
  gem "pygmentize"
  gem "mocha"
  gem "vcr"
  gem "webmock"
  gem "simplecov", "~> 0.4.0", :require => false
  gem "launchy"
  gem "jammit"
end

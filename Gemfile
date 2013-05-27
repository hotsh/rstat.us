source 'http://rubygems.org'

gem 'rails',                    '3.2.12'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem "sass",                   "~> 3.1.10"
  gem 'sass-rails',             "~> 3.2.5"
  gem 'compass-rails',          "~> 1.0.3"
  gem 'coffee-rails',           "~> 3.2.2"
  gem 'uglifier',               "~> 1.0.0"
  gem 'jquery-ui-rails',        "~> 2.0.0"

  # Many Linux environments do not have a javascript environment which is
  # required by the asset generators. However, windows and os x have one
  # provided by the system.
  gem "therubyracer",           "~> 0.11.3" unless RUBY_PLATFORM.match(/darwin|mswin/)
end

gem "haml",                     "~> 3.1.4"
gem "haml-rails",               "~> 0.3.4"
gem 'jquery-rails',             "~> 1.0.12"
gem 'airbrake',                 "~> 3.0.9"
gem 'bcrypt-ruby',              "~> 3.0.0"
gem 'omniauth',                 "~> 1.1.0"
gem "omniauth-twitter",         "~> 0.0.12"
gem "mongo_mapper",             "~> 0.12.0"
gem "mongo",                    "~> 1.7.0"
gem "bson",                     "~> 1.7.0"
gem "bson_ext",                 "~> 1.7.0"
gem "i18n",                     "~> 0.6.0"
gem "tire",                     "~> 0.4.1"
gem "twitter",                  "~> 4.6.0"
gem "pony",                     "~> 1.3"
gem "rdiscount",                "~> 1.6.8"
gem "ratom",                    "~> 0.7.2"
gem "ostatus",                  "~> 0.0.12"
gem "osub",                     "~> 0.0.6"
gem "opub",                     "~> 0.0.1"
gem "redfinger",                :git => "git://github.com/hotsh/redfinger.git"
gem "nokogiri",                 "~> 1.5.0"
gem "tzinfo",                   "~> 0.3.29"
gem "rsa",                      "~> 0.1.4"
gem "exceptional",              "~> 2.0.32"
gem "newrelic_rpm",             "~> 3.3.1"
gem "draper",                   "~> 0.11.1"

# background job queue
gem "delayed_job",              :git => "git://github.com/collectiveidea/delayed_job.git", :tag => "v2.1.4"
gem "delayed_job_mongo_mapper", :git => "git://github.com/earbits/delayed_job_mongo_mapper.git"
gem "whenever",                 "~> 0.6.8"

# web server

gem "puma",                     "~> 1.6.3"

group :development, :test do
  gem "database_cleaner",       "~> 0.6.7"
  gem "fabrication",            "~> 1.2.0"
  gem "capybara",               "~> 1.1.2"
  gem "show_me_the_cookies",    "~> 1.1.0"
  gem "rocco",                  :git => "git://github.com/rtomayko/rocco.git"
  gem "pygmentize",             "~> 0.0.3"
  gem "mocha",                  "~> 0.13.0", :require => false
  gem "vcr",                    "~> 1.10.3"
  gem "simplecov",              "~> 0.4.0", :require => false
  gem "launchy",                "~> 2.0.5"
  gem "minitest",               "~> 4.2.0"
  gem "quiet_assets",           "~> 1.0.0"
end

group :test do
  gem "webmock",                "~> 1.6.4"
end

source 'http://rubygems.org'

gem 'rails4_upgrade'
gem 'rails', github: 'rails/rails'

gem 'arel', github: 'rails/arel', branch: 'master'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem "sass",                   "~> 3.1.10"
  gem 'sass-rails', github: 'rails/sass-rails'
  gem 'sprockets-rails', github: 'rails/sprockets-rails'
  gem 'compass-rails',          "~> 1.0.3"
  gem 'coffee-rails', github: 'rails/coffee-rails'
  gem 'uglifier',               "~> 1.0.0"
  gem 'jquery-ui-rails',        "~> 2.0.0"
end

gem "haml",                     "~> 3.1.4"
gem "haml-rails",               "~> 0.3.4"
gem 'jquery-rails',             "~> 2.1.4"
gem 'airbrake',                 "~> 3.0.9"
gem 'bcrypt-ruby',              "~> 3.0.0"
gem 'thin',                     "~> 1.5.0"
gem 'omniauth',                 "~> 1.1.0"
gem "omniauth-twitter",         "~> 0.0.12"
gem "mongo_mapper", path: '~/Ruby/mongomapper'
gem "mongo",                    "~> 1.8.0"
gem "bson",                     "~> 1.8.0"
gem "bson_ext",                 "~> 1.8.0"
gem "i18n",                     "~> 0.6.0"
gem "tire",                     "~> 0.4.1"
gem "twitter",                  "~> 3.5.0"
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
gem "draper",                   "~> 0.11.1"

group :production do
  gem 'unicorn',                "~> 4.0.1"
end

group :development, :test do
  gem "database_cleaner",       "~> 0.6.7"
  gem "fabrication",            "~> 1.2.0"
  gem "capybara",               "~> 1.1.2"
  gem "show_me_the_cookies",    "~> 1.1.0"
  gem "rocco",                  :git => "git://github.com/rtomayko/rocco.git"
  gem "pygmentize",             "~> 0.0.3"
  gem "mocha",                  "~> 0.13.0", require: false
  gem "vcr",                    "~> 1.10.3"
  gem "simplecov",              "~> 0.4.0", :require => false
  gem "launchy",                "~> 2.0.5"
  gem "minitest",               "~> 4.2.0"
end

group :test do
  gem "webmock",                "~> 1.6.4"
  gem "therubyracer",           "~> 0.9.9"
end

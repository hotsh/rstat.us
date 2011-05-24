require 'rubygems'
require 'bundler/setup'
require "sprockets"
require 'uglifier'
require 'sass'

require File.dirname(__FILE__) + '/rstatus'

ENV['RACK_ENV'] ||= "development"

unless ENV['RACK_ENV'] == "production"
  config = YAML.load_file(File.join(File.dirname(__FILE__) + '/config/config.yml'))[ENV['RACK_ENV']]

  config.each do |key, value|
    ENV[key] = value
  end
else
  require 'exceptional'
  use Rack::Exceptional, ENV['EXCEPTIONAL_KEY']
end

Assets = Sprockets::Environment.new(Rstatus.root.to_s)
Assets.static_root = File.join(Rstatus.root, "public", "assets")
Assets.paths << "assets"
Assets.logger = Rstatus.log
Assets.js_compressor = Uglifier.new
compressor = Object.new
def compressor.compress(source)
  Sass::Engine.new(source,
                   :syntax => :sass, :style => :compressed
                  ).render
end
Assets.css_compressor = compressor


map "/assets" do
  run Assets
end

map "/" do
  run Rstatus
end


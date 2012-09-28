# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.


if ENV["SECRET_TOKEN"].blank?
  if Rails.env.production?
    raise "You must set ENV[\"SECRET_TOKEN\"] in your app's config vars"
  elsif Rails.env.test?
    # Generate the key and test away
    ENV["SECRET_TOKEN"] = RstatUs::Application.config.secret_token = SecureRandom.hex(30)
  else
    config_file = File.expand_path(File.join(Rails.root, '/config/config.yml'))
    config = YAML.load_file(config_file)
    # Generate the key, set it for the current environment, update the yaml file and move on
    ENV["SECRET_TOKEN"] = config[Rails.env]['SECRET_TOKEN'] = SecureRandom.hex(30)
    File.open(config_file, 'w') { |file| file.write(config.to_yaml) }
  end
end

RstatUs::Application.config.secret_token = ENV["SECRET_TOKEN"]
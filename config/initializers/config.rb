unless Rails.env.production?
  config = YAML.load_file(File.join(Rails.root + '/config/config.yml'))[ENV['RAILS_ENV']]

  config.each do |key, value|
    ENV[key] = value
  end
end

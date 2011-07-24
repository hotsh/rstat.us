unless Rails.env.production?
  config = YAML.load_file(File.expand_path(File.join(Rails.root, '/config/config.yml')))[Rails.env]

  config.each do |key, value|
    ENV[key] = value
  end
end

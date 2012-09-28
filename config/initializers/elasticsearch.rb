if ENV['BONSAI_INDEX_URL']
  Tire.configure do
    url "http://index.bonsai.io"
  end
  ELASTICSEARCH_INDEX_NAME = ENV['BONSAI_INDEX_URL'][/[^\/]+$/]
else
  app_name = Rails.application.class.parent_name.underscore.dasherize
  app_env = Rails.env
  ELASTICSEARCH_INDEX_NAME = "#{app_name}-#{app_env}"
end
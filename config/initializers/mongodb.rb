if ENV['MONGOHQ_URL']
  MongoMapper.config = {ENV['RACK_ENV'] => {'uri' => ENV['MONGOHQ_URL']}}
  MongoMapper.database = ENV['MONGOHQ_DATABASE']
  MongoMapper.connect("production")
else
  MongoMapper.connection = Mongo::Connection.new('localhost')
  MongoMapper.database = "rstatus-#{Rails.env}"
end

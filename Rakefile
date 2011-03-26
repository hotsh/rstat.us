require 'rake/testtask'
require 'rake/clean'

task :environment do
  require(File.join(File.dirname(__FILE__),"rstatus")) 
end

Dir.glob("tasks/*.rake").each { |r| import r }

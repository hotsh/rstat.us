#rake tasks to update stored data
namespace :fixdb do
  task :generate_metadata => :environment do
     Update.find_each do |update|
       update.get_tags
       puts "'#{update.text}' => tags:#{update.tags}"
       update.set(:tags => update.tags)
     end
  end
end


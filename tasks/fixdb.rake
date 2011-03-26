#rake tasks to update stored data
namespace :fixdb do
  task :generate_metadata => :environment do
     Update.find_each do |update|
       update.get_tags
       update.get_language
       puts "'#{update.text}' => tags:#{update.tags}, lang: #{update.language}"
       update.set(:tags => update.tags, :language => update.language)
     end
  end
end


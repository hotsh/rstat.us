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

  task :keywords => :environment do
    Update.find_each do |update|
      update.send(:_update_keywords)
      update.set(:_keywords => update._keywords)
    end
  end
end


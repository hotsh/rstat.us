#rake tasks to update stored data
namespace :fixdb do
  desc "Generate language and tag metadata"
  task :generate_metadata => :environment do
     Update.find_each do |update|
       update.get_tags
       update.get_language
       puts "'#{update.text}' => tags:#{update.tags}, lang: #{update.language}"
       update.set(:tags => update.tags, :language => update.language)
     end
  end

  desc "Update keywords"
  task :keywords => :environment do
    Update.find_each do |update|
      update.send(:_update_keywords)
      update.set(:_keywords => update._keywords)
    end
  end

  desc "Fix any users who are following themselves"
  task :unfollow_self => :environment do
    User.find_each do |user|
      if user.following? user.feed.url
        user.unfollow! user.feed
      end
    end
  end
end


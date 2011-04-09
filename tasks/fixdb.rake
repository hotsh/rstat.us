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

  desc "Report duplicate usernames"
  task :report_duplicate_usernames => :environment do
    duplicate_usernames = []
    User.find_each do |user|
      unless duplicate_usernames.include?(user.username.downcase)
        users = User.all(:username => /^#{user.username}$/i)
        if users.size > 1
          puts "#{user.username} is in conflict with: #{users.reject {|u| u.id == user.id}.map {|u| u.username}.join(", ")}"
          duplicate_usernames << user.username.downcase
        end
      end
    end
  end

  desc "Fix users with duplicate usernames"
  task :undup_usernames => :environment do
    User.find_each do |user|
      users = User.all(:username => /^#{user.username}$/i)
      if users.size > 1
        puts "Username #{user.username} belonging to user #{user.id} is not unique"
        users.reject {|u| u.id == user.id}.each do |other_user|
          begin
            puts "Enter new username for user #{other_user.username} (#{other_user.id}):"
            other_user.username = STDIN.gets.chomp
            other_user.save! unless other_user.username == ""
          rescue Exception => exception
            puts exception.message
            retry
          end
        end
      end
    end
  end
end


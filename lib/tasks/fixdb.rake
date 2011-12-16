#rake tasks to update stored data
namespace :fixdb do
  desc "Set nil Author usernames"
  task :set_nil_usernames => :environment do
    messed_up_authors = Author.where(:username => nil)

    messed_up_authors.each do |author|
      user = User.where(:author_id => author.id).first
      if user
        if Author.count(:username => user.username) > 0
          puts "Can't set username for Author #{author.id}; Author with #{user.username} already exists"
        else
          author.set(:username => user.username)
          puts "Fixed user #{user.username}."
        end
      else
        puts "Couldn't fix Author #{author.id}; no user found"
      end
    end
  end
end
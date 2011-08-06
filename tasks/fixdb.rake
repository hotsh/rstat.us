#rake tasks to update stored data
namespace :fixdb do
  desc "Generate keys for existing users"
  task :generate_keys => :environment do
    User.find_each do |user|
      user.generate_rsa_pair
      user.save
    end
  end

  desc "Attach rstat.us domains to local Authors"
  task :generate_domains => :environment do
    User.find_each do |user|
      user.author.domain = "rstat.us"
      user.author.save
    end
  end

  desc "Use superfeedr as the hub for all feeds"
  task :change_hubs => :environment do
    User.find_each do |user|
      user.feed.hubs = ["http://rstatus.superfeedr.com/"]
      user.feed.save
    end
  end
end


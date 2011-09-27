Factory.define :feed do |f|
end

Factory.sequence :update_text do |i|
  "This is update #{i}"
end

Factory.define :update do |u|
  u.text { Factory.next(:update_text) }
  u.twitter false
  u.author { Factory(:author) }
  u.feed { |update| Factory(:feed, :author => update.author) }
end

Factory.sequence :usernames do |i|
  "user_#{i}"
end

Factory.sequence :emails do |i|
  "user_#{i}@example.com"
end

Factory.define :user do |u|
  u.username { Factory.next(:usernames) }
  u.email { Factory.next(:emails) }
  u.author {|a| Factory(:author, :username => a.username, :created_at => a.created_at, :email => a.email) }
end

Factory.sequence :integer do |i|
  i
end

Factory.define :authorization do |a|
  a.uid { Factory.next(:integer) }
  a.nickname "god"
  a.provider "twitter"
  a.oauth_token "abcd"
  a.oauth_secret "efgh"
  a.association :user
end

Factory.define :author do |a|
  a.feed { |author| Factory(:feed, :author => author) }
  a.username "user"
  a.email { Factory.next(:emails) }
  a.website "http://example.com"
  a.domain "foo.example.com"
  a.name "Something"
  a.bio "Hi, I do stuff."
end

Factory.define :feed do |f|
  f.user_id "1234"
  f.user_name "John Public"
  f.user_username "user_name"
  f.user_email "john@example.com"
  f.user_website "http://example.com"
end

Factory.sequence :update_text do |i|
  "This is update #{i}"
end

Factory.define :update do |u|
  u.text Factory.next(:update_text)
end

Factory.sequence :usernames do |i|
  "user_#{i}"
end

Factory.sequence :emails do |i|
  "user_#{i}@example.com"
end

Factory.define :user do |u|
  u.username Factory.next(:usernames)
  u.email Factory.next(:emails)
  u.website "http://example.com"
  u.name "Something"
end

Factory.sequence :integer do |i|
  i
end

Factory.define :authorization do |a|
  a.uid Factory.next(:integer)
  a.provider "twitter"
  a.association :user
end

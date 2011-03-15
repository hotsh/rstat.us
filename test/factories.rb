Factory.define :feed do |f|
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
end

Factory.sequence :integer do |i|
  i
end

Factory.define :authorization do |a|
  a.uid Factory.next(:integer)
  a.provider "twitter"
  a.association :user
end

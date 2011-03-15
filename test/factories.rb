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

Factory.define :user do |u|
  u.username Factory.next(:usernames)
end

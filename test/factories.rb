Factory.define :feed do |f|

end

Factory.sequence :update_text do |i|
  "This is update #{i}"
end

Factory.define :update do |u|
  u.text Factory.next(:update_text)
end

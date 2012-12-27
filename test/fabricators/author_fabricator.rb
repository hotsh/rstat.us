Fabricator(:author) do
  feed { |author| Fabricate(:feed, :author => author) }
  username  "user"
  email     { sequence(:email) { |i| "user_#{i}@example.com" } }
  website   "http://example.com"
  domain    "http://foo.example.com"
  name      "Something"
  bio       "Hi, I do stuff."
end

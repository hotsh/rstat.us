Fabricator(:user) do
  username { sequence(:username) { |i| "user_#{i}" } }
  email { sequence(:email) { |i| "user_#{i}@example.com" } }
  author { |a| Fabricate(:author, :username => a.username, :created_at => a.created_at, :email => a.email) }
end

Fabricator(:user) do
  username  { sequence(:username) { |i| "user_#{i}" } }
  email     { sequence(:email) { |i| "user_#{i}@example.com" } }
  author    { |user| Fabricate(:author, :username => user.username, :created_at => user.created_at, :email => user.email) }
end

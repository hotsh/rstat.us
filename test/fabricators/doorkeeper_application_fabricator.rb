Fabricator(:doorkeeper_application, from: Doorkeeper::Application) do
  name { sequence(:name) { |i| "Application #{i}" } }
  redirect_uri "http://localhost:3001/auth/callback"
end
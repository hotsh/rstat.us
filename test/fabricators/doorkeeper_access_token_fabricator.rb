Fabricator(:doorkeeper_access_token, from: Doorkeeper::AccessToken) do
  application { Fabricate(:doorkeeper_application) }
  resource_owner_id { Fabricate(:user).id }
end
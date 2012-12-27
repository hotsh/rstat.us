Fabricator(:authorization) do
  uid           { sequence(:uid) { |i| i } }
  nickname      "god"
  provider      "twitter"
  oauth_token   "abcd"
  oauth_secret  "efgh"
  user
end

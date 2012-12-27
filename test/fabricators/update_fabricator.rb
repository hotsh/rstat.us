Fabricator(:update) do
  text    { sequence(:text) { |i| "This is update #{i}" } }
  twitter false
  author
  feed    { |update| Fabricate(:feed, :author => update.author) }
end

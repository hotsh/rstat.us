RstatUs::Application.routes.draw do

  match "open_source" => "static#open_source"

  get "static/follow"

  match "contact" => "static#contact"

  match "help" => "static#help"

  root :to => "static#homepage"
end

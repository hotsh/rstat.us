RstatUs::Application.routes.draw do
  root :to => "static#homepage", :constraints => lambda {|x| x.session[:user_id] == nil}
  root :to => "updates#index", :constraints => lambda {|x| x.session[:user_id] != nil}

  # Sessions
  resources :sessions, :only => [:new, :create, :destroy]
  match "/login", :to => "sessions#new"
  match "/logout", :to => "sessions#destroy"

  get "static/follow"

  # Static
  match "contact" => "static#contact"
  match "open_source" => "static#open_source"
  match "help" => "static#help"

  # External Auth
  match '/auth/:provider/callback', :to => 'auth#auth'
  match '/auth/failure', :to => 'auth#failure'
  match '/users/:username/auth/:provider', :via => :delete, :to => "auth#destroy"

  # Users
  resources :users, :only => [:create]

  # Updates
  resources :updates, :only => [:index, :show, :create, :destroy]
  match "/timeline", :to => "updates#timeline"
  match "/replies", :to => "updates#replies"

  # Search
  resource :search, :only => :show
end

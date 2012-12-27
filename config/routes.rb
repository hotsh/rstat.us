RstatUs::Application.routes.draw do
  root :to => "static#homepage", :constraints => lambda {|x| x.session[:user_id] == nil}
  root :to => "updates#timeline", :constraints => lambda {|x| x.session[:user_id] != nil}

  # Sessions
  resources :sessions, :only => [:new, :create, :destroy]
  match "/login", :to => "sessions#new"
  match "/logout", :to => "sessions#destroy", :via => :post

  # Static
  match "about",       :to => "static#about"
  match "contact",     :to => "static#contact"
  match "follow",      :to => "static#follow", :via => :get
  match "help",        :to => "static#help"
  match "open_source", :to => "static#open_source"

  # External Auth
  # If we add more valid auth providers, they will need to be added
  # to this route's constraints
  match '/auth/:provider/callback', :to => 'auth#auth', :constraints => {:provider => /twitter/}
  match '/auth/:provider/callback', :to => 'auth#invalid_auth_provider'
  match '/auth/failure', :to => 'auth#failure'
  match '/users/:username/auth/:provider', :via => :delete, :to => "auth#destroy", :constraints => {:username => /[^\/]+/ }

  # Users
  match 'users/:id.:format', :to => "users#show", :constraints => { :id => /[^\/]+/, :format => /json/ }
  resources :users, :constraints => { :id => /[^\/]+/ }
  match 'users/:id/confirm_delete', :to => "users#confirm_delete", :constraints => { :id => /[^\/]+/ }, :as => "account_deletion_confirmation", :via => :get
  match "users/:id/feed", :to => "users#feed", :as => "user_feed", :constraints => { :id => /[^\/]+/ }
  match 'users/:id/followers', :to => "users#followers", :constraints => { :id => /[^\/]+/ }, :as => "followers"
  match 'users/:id/following', :to => "users#following", :constraints => { :id => /[^\/]+/ }, :as => "following"

  # Users - manage avatar
  match '/users/:username/avatar', :via => :delete, :to => "avatar#destroy", :constraints => {:username => /[^\/]+/ }, :as => "avatar"

  # Users - confirm email
  match 'confirm_email/:token', :to => "users#confirm_email"

  # Users - forgot/reset password
  match 'forgot_password', :to => "users#forgot_password_new", :via => :get, :as => "forgot_password"
  match 'forgot_password', :to => "users#forgot_password_create", :via => :post
  match 'forgot_password_confirm', :to => "users#forgot_password_confirm", :via => :get, :as => "forgot_password_confirm"
  match 'reset_password', :to => "users#reset_password_new", :via => :get
  match 'reset_password', :to => "users#reset_password_create", :via => :post
  match 'reset_password/:token', :to => "users#reset_password_with_token", :via => :get, :as => "reset_password"

  # Updates
  resources :updates, :only => [:index, :show, :create, :destroy]
  match "/timeline", :to => "updates#timeline"
  match "/replies", :to => "updates#replies"
  match "/export", :to => "updates#export", :via => :get

  # Search
  resource :search, :only => :show

  # Autocomplete
  get "/autocomplete" => "users#autocomplete", :format => "json"

  # feeds
  resources :feeds, :only => :show

  # Webfinger
  match '.well-known/host-meta', :to => "webfinger#host_meta"
  match 'users/:username/xrd.xml', :to => "webfinger#xrd", :as => "user_xrd", :constraints => { :username => /[^\/]+/ }

  # Salmon
  match 'feeds/:id/salmon', :to => "salmon#feeds"

  # Subscriptions
  resources :subscriptions, :except => [:update]
  match 'subscriptions/:id.atom', :to => "subscriptions#post_update", :via => :post
  match 'subscriptions/:id.atom', :to => "subscriptions#show", :via => :get
end

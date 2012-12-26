RstatUs::Application.routes.draw do
  root :to => "static#homepage", :constraints => lambda {|x| x.session[:user_id] == nil}
  root :to => "updates#timeline", :constraints => lambda {|x| x.session[:user_id] != nil}

  # Sessions
  resources :sessions, :only => [:new, :create, :destroy]
  get "/login", :to => "sessions#new"
  post "/logout", :to => "sessions#destroy"

  # Static
  get "about"       => "static#about"
  get "contact"     => "static#contact"
  get "follow"      => "static#follow"
  get "help"        => "static#help"
  get "open_source" => "static#open_source"

  # External Auth
  # If we add more valid auth providers, they will need to be added
  # to this route's constraints
  get '/auth/:provider/callback', :to => 'auth#auth', :constraints => {:provider => /twitter/}
  get '/auth/:provider/callback', :to => 'auth#invalid_auth_provider'
  get '/auth/failure', :to => 'auth#failure'
  delete '/users/:username/auth/:provider', :to => "auth#destroy", :constraints => {:username => /[^\/]+/ }

  # Users
  get 'users/:id.:format', :to => "users#show", :constraints => { :id => /[^\/]+/, :format => /json/ }
  resources :users, :constraints => { :id => /[^\/]+/ }
  get 'users/:id/confirm_delete', :to => "users#confirm_delete", :constraints => { :id => /[^\/]+/ }, :as => "account_deletion_confirmation"
  get "users/:id/feed", :to => "users#feed", :as => "user_feed", :constraints => { :id => /[^\/]+/ }
  get 'users/:id/followers', :to => "users#followers", :constraints => { :id => /[^\/]+/ }, :as => "followers"
  get 'users/:id/following', :to => "users#following", :constraints => { :id => /[^\/]+/ }, :as => "following"

  # Users - manage avatar
  delete '/users/:username/avatar', :to => "avatar#destroy", :constraints => {:username => /[^\/]+/ }, :as => "avatar"

  # Users - confirm email
  get 'confirm_email/:token', :to => "users#confirm_email"

  # Users - forgot/reset password
  get 'forgot_password', :to => "users#forgot_password_new", :as => "forgot_password"
  post 'forgot_password', :to => "users#forgot_password_create"
  get 'forgot_password_confirm', :to => "users#forgot_password_confirm", :as => "forgot_password_confirm"
  get 'reset_password', :to => "users#reset_password_new"
  post 'reset_password', :to => "users#reset_password_create"
  get 'reset_password/:token', :to => "users#reset_password_with_token", :as => "reset_password"

  # Updates
  resources :updates, :only => [:index, :show, :create, :destroy]
  get "/timeline", :to => "updates#timeline"
  get "/replies", :to => "updates#replies"
  get "/export", :to => "updates#export"

  # Search
  resource :search, :only => :show

  # Autocomplete
  get "/autocomplete" => "users#autocomplete", :format => "json"

  # feeds
  resources :feeds, :only => :show

  # Webfinger
  get '.well-known/host-meta', :to => "webfinger#host_meta"
  get 'users/:username/xrd.xml', :to => "webfinger#xrd", :as => "user_xrd", :constraints => { :username => /[^\/]+/ }

  # Salmon
  get 'feeds/:id/salmon', :to => "salmon#feeds"

  # Subscriptions
  resources :subscriptions, :except => [:update]
  post 'subscriptions/:id.atom', :to => "subscriptions#post_update"
  get 'subscriptions/:id.atom', :to => "subscriptions#show"
end

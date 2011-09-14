RstatUs::Application.routes.draw do
  root :to => "static#homepage", :constraints => lambda {|x| x.session[:user_id] == nil}
  root :to => "updates#timeline", :constraints => lambda {|x| x.session[:user_id] != nil}

  # Sessions
  resources :sessions, :only => [:new, :create, :destroy]
  match "/login", :to => "sessions#new"
  match "/logout", :to => "sessions#destroy"

  match "/follow", :to => "static#follow", :via => :get

  # Static
  match "contact" => "static#contact"
  match "open_source" => "static#open_source"
  match "help" => "static#help"
  # static for remote follows
  match "/follow", :to => "static#follow"

  # External Auth
  match '/auth/:provider/callback', :to => 'auth#auth'
  match '/auth/failure', :to => 'auth#failure'
  match '/users/:username/auth/:provider', :via => :delete, :to => "auth#destroy"

  # Users
  resources :users, :except => [:index]
  match "users/:id/feed", :to => "users#feed", :as => "user_feed"
  # other new route?
  match 'users/:id/followers', :to => "users#followers"
  match 'users/:id/following', :to => "users#following"
  match 'confirm_email/:token', :to => "users#confirm_email"
  match 'forgot_password', :to => "users#forgot_password_new", :via => :get
  match 'forgot_password', :to => "users#forgot_password_create", :via => :post
  match 'forgot_password_confirm', :to => "users#forgot_password_confirm", :via => :get
  match 'reset_password', :to => "users#reset_password_new", :via => :get
  match 'reset_password', :to => "users#reset_password_create", :via => :post
  match 'reset_password/:token', :to => "users#reset_password_with_token", :via => :get

  # Updates
  resources :updates, :only => [:index, :show, :create, :destroy]
  match "/timeline", :to => "updates#timeline"
  match "/replies", :to => "updates#replies"

  # Search
  resource :search, :only => :show

  # feeds
  resources :feeds, :only => :show

  # Webfinger
  match '.well-known/host-meta', :to => "webfinger#host_meta"
  match 'users/:username/xrd.xml', :to => "webfinger#xrd", :as => "user_xrd"

  # Salmon
  match 'feeds/:id/salmon', :to => "salmon#feeds"

  # Subscriptions
  resources :subscriptions, :except => [:update]
  match 'subscriptions/:id.atom', :to => "subscriptions#post_update", :via => :post
  match 'subscriptions/:id.atom', :to => "subscriptions#show", :via => :get
end

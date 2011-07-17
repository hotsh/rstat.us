RstatUs::Application.routes.draw do
  root :to => "static#homepage", :constraints => lambda {|x| x.session[:user_id] == nil}
  root :to => "dashboard#index", :constraints => lambda {|x| x.session[:user_id] != nil}

  resources :sessions, :only => [:new, :create, :destroy]

  match "/login", :to => "sessions#new"
  match "/logout", :to => "sessions#destroy"

  get "static/follow"

  match "contact" => "static#contact"
  match "open_source" => "static#open_source"
  match "help" => "static#help"
end

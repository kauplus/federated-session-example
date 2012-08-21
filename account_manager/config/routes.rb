AccountManager::Application.routes.draw do
  devise_for :users do
    # This could also be set in config, see:
    # http://stackoverflow.com/questions/6557311/no-route-matches-users-sign-out-devise-rails-3
    get '/users/sign_out' => 'devise/sessions#destroy'
  end
  
  # oauth routes can be mounted to any path (ex: /oauth2 or /oauth)
  mount Devise::Oauth2Providable::Engine => '/oauth2'
  
  mount Devise::Oauth2FederatedSession::Engine => '/federated'

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'application#index'
  
  match '/me' => 'application#me'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':controller(/:action(/:id))(.:format)'
end

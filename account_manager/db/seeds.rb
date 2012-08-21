Devise::Oauth2FederatedSession::Client.create(
  :name => 'Sinatra Client',
  :redirect_uri => 'http://localhost:9393/oauth/callback',
  :session_expired_notification_uri => 'http://localhost:9393/session_expired_notification',
  :website => 'http://localhost:9393/'
)

User.create!({:email => 'john@doe.com', :password => '111111', :password_confirmation => '111111' })
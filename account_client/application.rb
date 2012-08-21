require 'debugger'
require 'sinatra/base'
require 'oauth2'

class Application < Sinatra::Base
  enable :sessions
  
  configure(:development) do
    
    # Enable sessions
    set :session_secret, "something"
    
  end
  
  APP_ROOT = 'http://localhost:9393'
  
  OAUTH_PROVIDER_URL = 'http://localhost:3000'
  OAUTH_CALLBACK_URL = "#{APP_ROOT}/oauth/callback"
  
  # Get an authorization code
  OAUTH_PROVIDER_AUTHORIZE_PATH = '/federated/authorize'
  
  # Get a new token
  OAUTH_PROVIDER_TOKEN_PATH = '/federated/sessions/create'
  
  # Used to check if the user is still logged in.
  # Can be used instead of client notifications.
  OAUTH_PROVIDER_IS_ALIVE_PATH = '/federated/sessions/is_alive'
  
  CLIENT_ID = 'e5aebde4e04d29e5bd59fc733c7b7fa5'
  CLIENT_SECRET = '59723252b30087295531bcc828922ea4'
  
  #
  # Oauth2 client
  #
  def client
    @client ||= OAuth2::Client.new CLIENT_ID, CLIENT_SECRET, {
      :site => OAUTH_PROVIDER_URL,
      :authorize_url => OAUTH_PROVIDER_AUTHORIZE_PATH,
      :token_url => OAUTH_PROVIDER_TOKEN_PATH
    }
  end
  
  def token_expired?(token)
    cache = YAML.load(File.read(File.expand_path('../cache.yml', __FILE__)))
    (cache['tokens'] || []).include?(token.to_s)
  end
  
  def add_expired_token(token)
    cache = YAML.load(File.read(File.expand_path('../cache.yml', __FILE__)))
    cache['tokens'] ||= []
    cache['tokens'] << token
    File.open(File.expand_path('../cache.yml', __FILE__), 'w') {|f| f.write(YAML.dump(cache))}
  end
  
  def is_alive
    begin
      resp = OAuth2::AccessToken.new(client, session[:token]).get(OAUTH_PROVIDER_IS_ALIVE_PATH)
      resp.body == 'true'
    rescue Exception => ex
      puts ex.message
      puts ex.backtrace
      raise
    end
  end
  
  before do
    if token_expired?(session[:token])
      puts "==== Clearing session because an expiration notification was received"
      session.clear
    end
  end
  
  after do
    puts "\nCompleted #{response.status}\n"
  end
  
  get '/' do
    redirect '/browse'
  end
  
  #
  # Use case 1. Only authenticated users are allowed, and session validation
  # is done using the "is_alive" method.
  #
  get '/admin' do
    if session[:user_id] && is_alive
      erb :index
    else
      session[:user_redirect_uri] = '/admin'
      redirect client.auth_code.authorize_url
    end
  end
  
  #
  # Use case 2. Anonymous users are allowed but, if this is the first
  # pageview of the session, check if the user is already has an active
  # session.
  #
  get '/browse' do
    # debugger
    if session[:existing_session]
      puts "==== Session was already active"
      # Don't care if we know who the user is (this is a public page)
      erb :index
    else
      puts "==== Starting new session with initial redirect"
      session[:existing_session] = true
      session[:user_redirect_uri] = 'http://localhost:9393/browse'
      redirect "#{OAUTH_PROVIDER_URL}/federated/sessions/recognize_user?response_type=code&client_id=#{CLIENT_ID}&redirect_uri=http://localhost:9393/browse"
    end
    
  end
  
  #
  # Another example of Use Case 2.
  #
  get '/listing' do
    if session[:existing_session]
      # Don't care if we know who the user is (this is a public page)
      erb :listing
    else
      session[:existing_session] = true
      session[:user_redirect_uri] = 'http://localhost:9393/listing'
      redirect "#{OAUTH_PROVIDER_URL}/federated/sessions/recognize_user?response_type=code&client_id=#{CLIENT_ID}&redirect_uri=http://localhost:9393/listing"
    end
  end
  
  #
  # Use Case 3. Only authenticated users are allowed, but session validation
  # is done using client notifications.
  #
  get '/my_profile' do
    if session[:user_id]
      puts "==== User was already logged in"
      erb :profile
    else
      puts "==== User was not logged in; redirecting"
      session[:user_redirect_uri] = '/my_profile'
      redirect client.auth_code.authorize_url
    end
  end
  
  #
  # Clear the session; used to test the "recognize_user" action.
  #
  get '/new_session' do
    if session[:existing_session]
      puts "==== Renewing session"
      session.clear
    else
      puts "==== Session was already new, no need to erase :existing_session"
    end
  end
  
  #
  # The OAuth2 provider redirects the user here with 
  # the authorization code.
  #
  get '/oauth/callback' do
    
    if params[:error] # handle access_denied
      @error = params[:error]
      erb :error
    end
    
    begin # code remains valid for 1 min
      access_token = client.auth_code.get_token params[:code], :redirect_uri => OAUTH_CALLBACK_URL
      
      # Access user's protected resources
      user = JSON.load(access_token.get('/me').body)
      
      # Save session information
      session[:token] = access_token.token
      session[:user_id] = user['id']
      
      puts "Added session #{session[:token]} to cache"
      
      redirect (session[:user_redirect_uri] || '/')
      
    rescue OAuth2::Error => e
      @error = e
      erb :error
    end
    
  end
  
  #
  # The session manager uses this path to notify us
  # of expired sessions.
  #
  post '/session_expired_notification' do
    
    # Could validate host, or some HTTP header to confirm
    # that it is the provider making this request.
    
    puts "Expiring session #{params[:token]}"
    
    # Do something with this information,
    # such as forcing the Rack session to expire, or marking
    # this access token as expired and check every request if
    # the session is ok.
    add_expired_token(params[:token])
    
    # Return 200 OK
    200
    
  end
  
  get '/logout' do
    
    # Logout from the client application.
    session.clear
    
    # Redirect user to session manager logout.
    redirect "#{OAUTH_PROVIDER_URL}/federated/sessions/destroy?client_id=#{CLIENT_ID}&redirect_uri=#{APP_ROOT}"

  end
  
end
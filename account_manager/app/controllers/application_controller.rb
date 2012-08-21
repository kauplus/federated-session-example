class ApplicationController < ActionController::Base
  before_filter :authenticate_user!
  
  def index
  end
  
  def me
    render :json => { id: 1, name: 'John' }
  end
  
end

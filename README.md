Federated Session Example
===============================

This repository contains two example applications (`account_manager` and `account_client`) that demonstrate how to use the [devise-oauth2\_federated\_session gem](https://github.com/kauplus/devise-oauth2_federated_session).

Account manager
----------------

This is a Rails 3.2 application. Execute the following steps to get it up and running:

    cd account_manager
    
    bundle install
    
    rake db:create
    rake db:migrate
    rake db:seed
    
    rails s


Account client
--------------

This is a Sinatra application. To get it up and running, update the CLIENT_ID and CLIENT_SECRET in `application.rb`according to the values generated by the account manager and execute the following steps:

    cd account_client
    bundle exec shotgun
    

Now, go to <http://localhost:9393> and have fun!


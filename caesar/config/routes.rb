Rails.application.routes.draw do
  post '/get_access_token', to 'banking#get_access_token'
  get '/transactions', to 'banking#transactions'
  get '/auth', to 'banking#auth'
  get '/identity', to 'banking#identity'
  get '/balance', to 'banking#balance'
  get '/accounts', to 'banking#accounts'
  get '/item', to 'banking#item'
  get '/assets', to 'banking#assets'
  get '/holdings', to 'banking#holdings'
  get '/investment_transactions', to 'banking#investment_transactions'
  post '/set_access_token', to 'banking#set_access_token'
end

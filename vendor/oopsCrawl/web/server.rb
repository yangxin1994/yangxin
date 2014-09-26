require File.expand_path('../../lib/model', __FILE__) 
require 'sinatra'

get '/hi' do
  "Hello World!"
end

get '/index' do
  erb :index
end

get '/weibo/accounts' do
  @accounts = Account.all
  erb :weibo_account
end
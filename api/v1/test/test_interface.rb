require 'sinatra'
require 'sinatra/activerecord'
require 'activerecord-import'
require 'byebug'
require 'bcrypt'
require 'time_difference'
require 'time'
require 'json'
require 'rest-client'
require 'sinatra/cors'
require 'securerandom'
require 'redis'
require_relative 'user_helper'
#require_relative 'prefix.rb'
require_relative 'models/user'
require_relative 'models/follow'

PREFIX = '/api/v1'

get '/test/random' do
  User.order('RANDOM()').first.id
end

post '/testcreate' do
  puts params
  user = nil
  if params['id'].nil?
    user = User.new(username: params['username'], password: params['password'], email: params['email'], number_of_followers: 0, number_of_leaders: 0)
  else
    user = User.new(id: params['id'],username: params['username'], password: params['password'], email:params['email'], number_of_followers: 0, number_of_leaders: 0)
  end
  if user.save
     token = SecureRandom.hex
     user_hash = Hash.new
     tokenized(user_hash,token,user.id,user.username)
     user_log = create_user_log(user)
     return user.id.to_json
  end
  {err: true}.to_json
end

get '/test/remove' do
  $redis.del params['username'] if $redis.get params['username']
  User.find_by_username(params['username']).destroy
end

get '/test/status' do
  "number of users: #{User.count}"
end

post '/bulkinsert' do
  values = JSON.parse(params['bulk'])
  User.import values, :validate => false
end

# Danger Zone
post '/removeall' do
  $redis_follow.flushall
  $redis.flushall
  User.destroy_all
end

# Calling this will prevent activerecord from assigning the same id (which violates constrain)
def reset_db_peak_sequence
  ActiveRecord::Base.connection.tables.each do |t|
    ActiveRecord::Base.connection.reset_pk_sequence!(t)
  end
end

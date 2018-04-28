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
HELPER = UserHelper.new

configure do
    uri = URI.parse(ENV['REDISCLOUD_URL'])
    $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    uri2 = URI.parse(ENV['REDISCLOUD_FOLLOW'])
    $redis_follow = Redis.new(:host => uri2.host, :port => uri2.port, :password => uri2.password)
end

set :allow_origin, '*'
set :allow_methods, 'GET,HEAD,POST'
set :allow_headers, 'accept,content-type,if-modified-since'
set :expose_headers, 'location,link'


Dir[File.dirname(__FILE__) + '/api/v1/test/*.rb'].each { |file| require file }

configure :production do
  require 'newrelic_rpm'
end

# For loader.io to auth
get '/loaderio-bf4a2013f6f1a1d87c7eea9ff1c17eb5.txt' do
  send_file 'loaderio-bf4a2013f6f1a1d87c7eea9ff1c17eb5.txt'
end

# Login function. Bcrypt does take a long time
post PREFIX + '/login' do
  first_try = $redis.get params['username']
  if (first_try && BCrypt::Password.new(JSON.parse(first_try)["password"]) == params['password'])
    first_try = JSON.parse(first_try)
    result = HELPER.redis_login(first_try["id"],params['username'])
    return result.to_json
  else
    @user = User.find_by_username(params['username'])
    if !@user.nil? && @user.password == params['password']
      result = HELPER.database_login(@user)
      return result.to_json
    end
  end
  {err: true}.to_json
end

# Register function. If successful, store the basic user info on redis
post PREFIX + '/users/register' do
  username = params['username'].to_s
  password = params['password'].to_s
  email = params['email'].to_s
  user = User.new(username: username, password: password, email:email, number_of_followers: 0, number_of_leaders: 0)
  HELPER.reset_db_peak_sequence
  if user.save
     token = SecureRandom.hex
     user_hash = Hash.new
     HELPER.tokenized(user_hash,token,user.id,user.username)
     user_log = HELPER.create_user_log(user)
     u_hash = user.as_json
     u_hash['id'] = u_hash['id'].to_s
     u_hash['leaders'] = []
     return {user: u_hash, token: token}.to_json
  end

  {err: true}.to_json
end

post '/test/insert' do
  username = params['username'].to_s
  password = params['password'].to_s
  email = params['email'].to_s
  user = User.new(id:params['id'],username: username, password: password, email:email, number_of_followers: 0, number_of_leaders: 0)

  if user.save
     user_log = HELPER.create_user_log(user)
     return {user: user.as_json}.to_json
  end

  {err: true}.to_json
end

#logout delete token session on redis
post PREFIX + '/:token/logout' do
  if $redis.get params['token']
    $redis.del params['token']
    return {err: false}.to_json
  end
  {err: true}.to_json
end


#Get User
get PREFIX + '/:token/users/:id' do
  if $redis.get params['token']
    first_try = JSON.parse($redis.get params['id'])
    if first_try
      return first_try.to_json
    else
      user = User.find params['id']
      if user
        u_hash = user.as_json
        u_hash['id'] = u_hash['id'].to_json
        return u_hash.to_json
      end
    end
  end
  {err: true}.to_json
end

post PREFIX + '/users/exists' do
  results = []
  User.where(username: JSON.parse(params[:usernames])).pluck(:username, :id).each do |r|
    results << (r[1].to_s + '-' + r[0].to_s)
  end
  results.to_json
end

get '/:id' do
  if User.exists?(params['id'].to_i)
    return User.find(params['id'].to_i).username
  end
  {err: true}.to_json
end

get PREFIX + '/:token/users/:id' do
  session =  $redis.get params['token']
  session = true if params['token'] == 'testuser'
  if session
    if User.exists?(params['id'].to_i)
      return User.find(params['id'].to_i).as_json.to_json
    end
  end
  {err: true}.to_json
end

get '/users/:username/username' do
  user = User.find_by_username(params['username'])
  if user
    user_arr = []
    user_arr << user.as_json
    return user_arr.to_json
  end
  {err: true}.to_json
end

get PREFIX + '/users/search/:pattern' do
  result = []
  potential_list = User.where("username like ?", "%#{params[:pattern]}%")
  potential_list.each do |user|
    sub_user_hash = Hash.new
    sub_user_hash[:id] = user.id
    sub_user_hash[:username] = user.username
    result << sub_user_hash
  end
  return result.to_json
end

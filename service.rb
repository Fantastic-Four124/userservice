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

# # Create token for user and store the key user information on redis
# def tokenized(user_hash,token,id,username)
#   user_hash["id"] = id
#   user_hash["username"] = username
#   $redis.set token, user_hash.to_json
#   $redis.expire token, 432000
# end
#
# # If user info is not found in redis, we check database
# def database_login(user)
#   token = SecureRandom.hex
#   user_hash = Hash.new
#   tokenized(user_hash,token,user.id,user.username)
#   u_hash = user.as_json
#   u_hash['leaders'] = []
#   u_hash['id'] = u_hash['id'].to_s
#   user.leaders.each {|l| u_hash['leaders'].push l.id.to_s}
#   return {user: u_hash, token: token}
# end

# Check userinfo on redis
# def redis_login(id,username)
#   user_hash = Hash.new
#   token = SecureRandom.hex
#   tokenized(user_hash,token,id,username)
#   u_hash = JSON.parse($redis.get(id))
#   u_hash['leaders'] = JSON.parse($redis_follow.get(id.to_s + ' leaders')).keys if $redis_follow.get(id.to_s + ' leaders')
#   u_hash['id'] = u_hash['id'].to_s
#   if u_hash['leaders'].nil?
#       u_hash['leaders'] = []
#       user = User.find(id)
#       user.leaders.each {|l| u_hash['leaders'].push l.id.to_s}
#   end
#   return {user: u_hash, token: token}
# end

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

# When a user is created, we put some user info on redis so that we can check it later when user logs in.
# The key info includes id,username, and bcrypted password

# def create_user_log(user)
#   user_log = Hash.new
#   user_log["password"] = user.password
#   user_log["id"] = user.id.to_s
#   u_hash = user.as_json
#   u_hash['id'] = u_hash['id'].to_s
#   $redis.set user.id, u_hash.to_json
#   $redis.set user.username, user_log.to_json
#   return user_log
# end

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

get '/users/:username/username' do
  user = User.find_by_username(params['username'])
  if user
    user_arr = []
    user_arr << user.as_json
    return user_arr.to_json
  end
  {err: true}.to_json
end

get '/users/search/:pattern' do
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

# def reset_db_peak_sequence
#   ActiveRecord::Base.connection.tables.each do |t|
#     ActiveRecord::Base.connection.reset_pk_sequence!(t)
#   end
# end

# get '/test/random' do
#   User.order('RANDOM()').first.id
# end
#
# post '/testcreate' do
#   user = nil
#   if params['id'].nil?
#     user = User.new(username: params['username'], password: params['password'], email: params['email'], number_of_followers: 0, number_of_leaders: 0)
#   else
#     user = User.new(id: params['id'],username: params['username'], password: params['password'], email:params['email'], number_of_followers: 0, number_of_leaders: 0)
#   end
#   if user.save
#      token = SecureRandom.hex
#      user_hash = Hash.new
#      tokenized(user_hash,token,user.id,user.username)
#      user_log = create_user_log(user)
#      return user.id.to_json
#   end
#   {err: true}.to_json
# end
#
# get '/test/remove' do
#   $redis.del params['username'] if $redis.get params['username']
#   User.find_by_username(params['username']).destroy
# end
#
# get '/test/status' do
#   "number of users: #{User.count}"
# end
#
# post '/bulkinsert' do
#   values = JSON.parse(params['bulk'])
#   User.import values, :validate => false
# end
#
# # Danger Zone
# post '/removeall' do
#   $redis_follow.flushall
#   $redis.flushall
#   User.destroy_all
# end
#
# # Calling this will prevent activerecord from assigning the same id (which violates constrain)
# def reset_db_peak_sequence
#   ActiveRecord::Base.connection.tables.each do |t|
#     ActiveRecord::Base.connection.reset_pk_sequence!(t)
#   end
# end

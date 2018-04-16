require 'sinatra'
require 'sinatra/activerecord'
require 'byebug'
require 'bcrypt'
#require_relative 'test_interface.rb'
require 'time_difference'
require 'time'
require 'json'
require 'rest-client'
require 'sinatra/cors'
require 'securerandom'
require 'redis'
require_relative 'prefix.rb'
#require_relative 'erb_constants.rb'
require_relative 'models/user'
require_relative 'models/follow'

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

Dir[File.dirname(__FILE__) + '/api/v1/user/*.rb'].each { |file| require file }

enable :sessions

configure :production do
  require 'newrelic_rpm'
end


# Small helper that minimizes code
helpers do
  def protected!
    #return settings.twitter_client # for testing only
    return !session[:username].nil?
  end

  def identity
    session[:username] ? session[:username] : 'Log in'
  end
end

# For loader.io to auth
get '/loaderio-bf4a2013f6f1a1d87c7eea9ff1c17eb5.txt' do
  send_file 'loaderio-bf4a2013f6f1a1d87c7eea9ff1c17eb5.txt'
end

post PREFIX + '/login' do
  first_try = JSON.parse($redis.get params['username'])
  if (first_try && BCrypt::Password.new(first_try["password"]) == params['username'])
    user_hash = Hash.new
    user_hash["id"] = first_try["id"]
    user_hash["username"] = params['username']
    token = SecureRandom.hex
    $redis.set token, user_hash.to_json
    $redis.expire token, 432000
    u_hash = JSON.parse($redis.get(first_try["id"]))
    u_hash['leaders'] = $redis_follow.get(first_try["id"].to_s + ' leaders')
    if !u_hash['leaders']
        puts "https://fierce-garden-41263.herokuapp.com/api/v1/#{params[:token].to_s}/users/#{first_try["id"].to_s}/leader-list"
        u_hash['leaders'] = JSON.parse(RestClient.get "https://fierce-garden-41263.herokuapp.com/api/v1/#{params[:token].to_s}/users/#{first_try["id"].to_s}/leader-list", {})
    end
    return {user: u_hash, token: token}.to_json
  else
    @user = User.find_by_username(params['username'])
    if !@user.nil? && @user.password == params['password']
      token = SecureRandom.hex
      user_hash = Hash.new
      user_hash["id"] = @user.id
      user_hash["username"] = @user.username
      $redis.set token, user_hash.to_json
      $redis.expire token, 432000
      u_hash = @user
      puts "https://fierce-garden-41263.herokuapp.com/api/v1/#{params[:token].to_s}/users/#{first_try["id"].to_s}/leader-list"
      u_hash['leaders'] = JSON.parse(RestClient.get "https://fierce-garden-41263.herokuapp.com/api/v1/#{params[:token].to_s}/users/#{first_try["id"].to_s}/leader-list", {})
      #Try
      # u_hash['leaders'] = []
      # u_hash['followers'] = []
      # @user.leaders.each
      # {|l| u_hash['leaders'].push l.id}
      # @user.followers.each {|f| u_hash['followers'].push f.id}
      return {user: u_hash, token: token}.to_json
    end
  end

  {err: true}.to_json
end


post PREFIX + '/users/register' do
  puts params['username']
  username = params['username'].to_s
  password = params['password'].to_s
  email = params['email'].to_s
  user = User.new(username: username, password: password, email:email, number_of_followers: 0, number_of_leaders: 0)

  if user.save
     token = SecureRandom.hex
     user_hash = Hash.new
     user_log = Hash.new
     user_hash["id"] = user.id
     user_hash["username"] = user.username
     user_log["password"] = user.password
     user_log["id"] = user.id
     u_hash = user

     $redis.set user.id, u_hash.to_json
     $redis.set username, user_log.to_json
     $redis.set token, user_hash.to_json
     $redis.expire token, 432000

     # puts JSON.parse($redis.get user.id)
     # puts JSON.parse($redis.get username)
     puts token
     puts JSON.parse($redis.get token)


     # u_hash['leaders'] = []
     # u_hash['followers'] = []

     return {user: u_hash, token: token}.to_json
  end

  {err: true}.to_json
end

post PREFIX + '/:token/logout' do
  if $redis.get params['token']
    $redis.del params['token']
    return {err: false}.to_json
  end
  {err: true}.to_json
end

get PREFIX + '/:token/users/:id' do
  first_try = JSON.parse($redis.get params['id'])
  if $redis.get params['token']
    if first_try
      return first_try.to_json
    else
      user = User.find params['id']
      if user
        u_hash = user.as_json
        # u_hash['leaders'] = []
        # u_hash['followers'] = []
        # user.leaders.each {|l| u_hash['leaders'].push l.id}
        # user.followers.each {|f| u_hash['followers'].push f.id}
        return u_hash.to_json
      end
    end
  end
  {err: true}.to_json
end

post '/test/reset/all' do
  clear_all
  recreate_testuser(params)
end

post '/test/reset/testuser' do
  remove_everything_about_testuser(params['username'])
  recreate_testuser(params)
end


def recreate_testuser(params)
  result = User.new(id: params['user_id'], username: params['username'], password: params['password'], email:params['email']).save
end

def clear_all()
  User.destroy_all
end

def remove_everything_about_testuser(testuser_name)
  list_of_activerecords = [
    User.find_by(username: testuser_name)
  ]
  list_of_activerecords.each { |ar| destroy_and_save(ar) }
end

def destroy_and_save(active_record_object)
  return if active_record_object == nil
  active_record_object.destroy
  active_record_object.save
end

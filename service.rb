require 'sinatra'
require 'sinatra/activerecord'
require 'byebug'
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
    #byebug
end

set :allow_origin, '\*'
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
  @user = User.find_by_username(params['username'])
  if !@user.nil? && @user.password == params['password']
    token = SecureRandom.hex
    $redis.set token, @user.id
    $redis.expire token, 432000
    u_hash = @user.as_json
    u_hash['leaders'] = []
    u_hash['followers'] = []
    @user.leaders.each {|l| u_hash['leaders'].push l.id}
    @user.followers.each {|f| u_hash['followers'].push f.id}
    return {user: u_hash, token: token}.to_json
  end

  {err: true}.to_json
end


post PREFIX + '/user/register' do
  puts params['username']
  username = params['username'].to_s
  password = params['password'].to_s
  email = params['email'].to_s
  user = User.new(username: username, password: password, email:email)

  if user.save
     token = SecureRandom.hex
     user_hash = Hash.new
     user_hash["id"] = user.id
     user_hash["username"] = user.username
     $redis.set token, user_hash.to_json
     $redis.expire token, 432000

     u_hash = user.as_json
     u_hash['leaders'] = []
     u_hash['followers'] = []

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

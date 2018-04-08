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
    uri = URI.parse("redis://rediscloud:5lKsZnGwfn5y9O12JAQ7T8vIWAKrr0P8@redis-16859.c14.us-east-1-3.ec2.cloud.redislabs.com:16859")
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
get '/loaderio-1541f51ead65ae3319ad8207fee20f8d.txt' do
  send_file 'loaderio-1541f51ead65ae3319ad8207fee20f8d.txt'
end

post PREFIX + '/login' do
  @user = User.find_by_username(params['username'])
  if !@user.nil? && @user.password == params['password']
    token = SecureRandom.hex
    $redis.set token, user.id
    $redis.expire token, 432000
    u_hash = user.as_json
    u_hash['leaders'] = []
    u_hash['followers'] = []
    user.leaders.each {|l| u_hash['leaders'].push l.id}
    user.followers.each {|f| u_hash['followers'].push f.id}
    return {user: u_hash, token: token}.to_json
  end

  {err: true}.to_json
end


post PREFIX + '/user/register' do
  username = params['username']
  password = params['password']
  email = params['email']
  user = User.new(username: username, password: password, email:email)

  if user.save
     token = SecureRandom.hex
     $redis.set token, user.id
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

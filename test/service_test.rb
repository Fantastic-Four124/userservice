require 'minitest/autorun'
require 'rack/test'
require 'rake/testtask'
require 'json'
require 'rest-client'
require_relative '../service.rb'
require_relative '../erb_constants.rb'
require_relative '../prefix.rb'

# These tests are not done yet! They still need to be filled out as we think of new functionality.

class ServiceTest < Minitest::Test

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def clearRedis
    while $redis.llen('global') > 0
      $redis.rpop('global')
    end
  end

  def setup
    @jim = User.create({username: 'jim', password: 'abc', email: 'jim@jim.com'})
    @bob = User.create({username: 'bob', password: 'abc', email: 'bob@bob.com'})
    @jim_id = User.find_by_username('jim').id
    @bob_id = User.find_by_username('bob').id
    @follow_test = Follow.create({user_id: @jim_id, leader_id: @bob_id})
    #clearRedis
  end

#   def teardown
#     @jim.destroy
#     @bob.destroy
#     #not_logged_in
#     #clearRedis
#   end

  def test_user
    check = User.find_by_username('jim').email
    assert_equal(check,'jim@jim.com')
  end

  def test_follow
    check = Follow.find_by_user_id(@jim_id).leader_id
    assert_equal(check,@bob_id)
  end

  def test_login
    param = { 'username' => 'jim', 'password' => 'abc' }
    response = post PREFIX + '/login', param.to_json
    puts JSON.parse(response)
    assert last_response.ok?
  end




  # def logged_in
  #   get PREFIX + '/', {}, { 'rack.session' => {user_id: @jim.id, user_hash: @jim, username: @jim.username} }
  # end
  #
  # def not_logged_in
  #   get PREFIX + '/', {}, { 'rack.session' => {username: nil} }
  # end
  #
  # def test_home
  #   not_logged_in
  #   #byebug
  #   assert last_response.ok? && (last_response.body.include? 'Login to nanoTwitter')
  # end
  #
  # def test_login_page
  #   not_logged_in
  #   get PREFIX + '/login'
  #   assert last_response.ok? && (last_response.body.include? 'Login to Nanotwitter') && (last_response.body.include? `<form action="#{PREFIX}/login" method="POST">`)
  # end
  #
  # def test_registration_page
  #   not_logged_in
  #   get PREFIX + '/user/register'
  #   assert last_response.ok? && (last_response.body.include? 'Register in Nanotwitter')
  # end
  #
  # def test_login_correctly
  #   not_logged_in
  #   get PREFIX + '/login'
  #   param = { 'username' => 'jim', 'password' => 'abc' }
  #   post PREFIX + '/login', param.to_json, "CONTENT_TYPE" => "application/json"
  #   assert last_response.ok?
  # end
  #
  # def test_home_logged_in
  #   logged_in
  #   get PREFIX + '/'
  #   assert last_response.ok?
  #   assert last_response.body.include?('jim')
  # end
  #
  # def test_login_incorrectly
  #   get PREFIX + '/login'
  #   param = { 'username' => 'obviously wrong', 'password' => 'wrong' }
  #   post PREFIX + '/login', param.to_json, "CONTENT_TYPE" => "application/json"
  #   assert last_response.body.include?("Wrong password or username.")
  # end
  #
  # def test_logout
  #   logged_in
  #   assert last_response.ok?
  #   assert last_response.body.include?('jim')
  #   post PREFIX + '/logout'
  #   get PREFIX + '/'
  #   assert last_response.ok?
  #   assert last_response.body.include?("Login to nanoTwitter")
  # end
end

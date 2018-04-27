require 'minitest/autorun'
require 'rack/test'
require 'rake/testtask'
require 'json'
require 'rest-client'
require_relative '../service.rb'
#require_relative '../erb_constants.rb'
#require_relative '../prefix.rb'

class ServiceTest < Minitest::Test

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    @jim = User.create({username: 'jim', password: 'abc', email: 'jim@jim.com'})
    @bob = User.create({username: 'bob', password: 'abc', email: 'bob@bob.com'})
    @jim_id = User.find_by_username('jim').id
    @bob_id = User.find_by_username('bob').id
    @follow_test = Follow.create({user_id: @jim_id, leader_id: @bob_id})
    @follow_test = Follow.create({user_id: @bob_id, leader_id: @jim_id})
  end

  def teardown
    @jim.destroy
    @bob.destroy
  end

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
    assert last_response.ok?
  end

  def test_register
    param = { 'username' => 'kentest', 'password' => 'abc', 'email' =>'ken@gmail.com' }
    response = post PREFIX + '/users/register', param.to_json
    assert last_response.ok?
  end

  def test_exists
    usernames = ['jim','bob']
    response = post PREFIX + '/users/exists', {'usernames' => usernames.to_json}
    assert last_response.ok?
  end

  def test_id
    response = get '/1'
    assert last_response.ok?
  end

  def test_find_username
    response = get '/users/jim/username'
    assert last_response.ok?
  end

end

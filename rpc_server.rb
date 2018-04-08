#!/usr/bin/env ruby
require 'bunny'
require 'thread'
require 'sinatra'
require 'sinatra/activerecord'
require 'byebug'
require_relative 'test_interface.rb'
require 'time_difference'
require 'time'
require 'json'
#require 'rest-client'
require 'redis'
require_relative 'prefix.rb'
require_relative 'erb_constants.rb'
require_relative 'models/follow'
require_relative 'models/user'
require_relative 'models/hashtag'
require_relative 'models/mention'
require_relative 'models/tweet'
require_relative 'models/hashtag_tweets'

#Dir[File.dirname(__FILE__) + '/api/v1/user_service/*.rb'].each { |file| require file }

class UserServer
  def initialize(id)
    @connection = Bunny.new(id)
    @connection.start
    @channel = @connection.create_channel
  end

  def start(queue_name)
    @queue = channel.queue(queue_name)
    @exchange = channel.default_exchange
    subscribe_to_queue
  end

  def stop
    channel.close
    connection.close
  end

  private

  attr_reader :channel, :exchange, :queue, :connection, :exchange2, :queue2

  def subscribe_to_queue
    queue.subscribe(block: true) do |_delivery_info, properties, payload|
      puts "[x] Get message #{payload}. Gonna do some user service about #{payload}"
      result = process(payload)
      puts result
      #byebug
      exchange.publish(
        result,
        routing_key: properties.reply_to,
        correlation_id: properties.correlation_id
      )
    end
  end

  def process(original)
    hydrate_original = JSON.parse(original)
    original_function = hydrate_original["function"]
    puts original_function
    original_candidate = hydrate_original["candidate"]
    feedback = ""
    if (original_function == 'register')
        feedback = post_new_user(original_candidate)
    elsif (original_function == 'get_user')
        feedback = get_user(original_candidate)
    end
    feedback
  end

  def post_new_user(raw_result)
    hydrate_result = JSON.parse(raw_result)
    username = hydrate_result['username']
  	password = hydrate_result['password']
    email = hydrate_result['email']
    @user = User.new(username: username)
    @user.password = password
    @user.email = email
    @user.number_of_followers = 0
    @user.number_of_leaders = 0
    feedback = ""
    if @user.save
      feedback = "register #{username} Successful"
    else
      feedback = "register #{username} Fail"
    end
  end

  def get_user(raw_result)
    hydrate_result = JSON.parse(raw_result)
    @user = User.find(hydrate_result)
    feedback = ""
    if !@user.nil?
      feedback = @user.to_json
    else
      feedback = "get #{user_id} Fail"
    end
  end

end


begin
  server = UserServer.new(ENV["RABBITMQ_BIGWIG_RX_URL"])

  puts ' [x] Awaiting RPC requests'
  server.start('rpc_queue')
  #server.start2('rpc_queue_hello')
rescue Interrupt => _
  server.stop
end

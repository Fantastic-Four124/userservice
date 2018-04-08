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

class UserClient
  attr_accessor :call_id, :response, :lock, :condition, :connection,
                :channel, :server_queue_name, :reply_queue, :exchange

  def initialize(server_queue_name,id)
    @connection = Bunny.new(id,automatically_recover: false)
    @connection.start

    @channel = connection.create_channel
    @exchange = channel.default_exchange
    @server_queue_name = server_queue_name

    setup_reply_queue
  end

  def call(n)
    @call_id = generate_uuid

    exchange.publish(n.to_s,
                     routing_key: server_queue_name,
                     correlation_id: call_id,
                     reply_to: reply_queue.name)

    # wait for the signal to continue the execution
    lock.synchronize { condition.wait(lock) }

    response
  end

  def stop
    channel.close
    connection.close
  end

  private

  def setup_reply_queue
    @lock = Mutex.new
    @condition = ConditionVariable.new
    that = self
    @reply_queue = channel.queue('', exclusive: true)

    reply_queue.subscribe do |_delivery_info, properties, payload|
      if properties[:correlation_id] == that.call_id
        that.response = payload

        # sends the signal to continue the execution of #call
        that.lock.synchronize { that.condition.signal }
      end
    end
  end

  def generate_uuid
    # very naive but good enough for code examples
    "#{rand}#{rand}#{rand}"
  end
end

client = UserClient.new('rpc_queue',ENV["RABBITMQ_BIGWIG_RX_URL"])


#thr = Thread.new {puts ' [x] Requesting fib(30)'; response = client.call(30);puts " [.] Got #{response}";}
#thr.join
# puts ' [x] Requesting fib(30)'
# response = client.call(30)
#
# puts " [.] Got #{response}"
count  = 0;
#loop do
  #puts "I am busy I can't wait"
  #count = count + 1
user = User.new(username: "zhoutest4")
user.password = "12345"
to_do = {:function => "register", :candidate =>user.to_json}
thr = Thread.new {
    puts " [x] Requesting #{user.username} and #{user.password}"; response = client.call(to_do.to_json);puts " [.] Got #{response}";
}
  # count = 0 if count == 30
  # #thr.join
  # puts "I am busy I can't wait"
  sleep 5.0
#end

client.stop

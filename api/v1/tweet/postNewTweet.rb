require 'rest-client'
require 'json'
require 'redis'

post PREFIX + '/tweets/new' do
  usr = session[:user_id]
  msg = params[:tweet]['message']
  mentions = Array.new
  hashtags = Array.new

  # Don't know how to use redis here yet. Need to consult with Zhengyang.
  #$redis.lpush('global', new_tweet.id)
  #$redis.rpop('global') if $redis.llen('global') > 50
  content = msg.split # Tokenizes the message
  content.each do |token|
    if /([@.])\w+/.match(token)
      term = token[1..-1]
      if User.find_by_username(term)
        mentions << term
      end
    elsif /([#.])\w+/.match(token)
      term = token[1..-1]
      hashtags << term
    end
  end
  #byebug
  #Yes, it must be hard-coded at the moment...
  response = RestClient.post 'https://nt-tweet-writer.herokuapp.com/api/v1/tweets/new', {contents: msg, user_id: usr, hashtags: hashtags.to_json, mentions: mentions.to_json}
  # response = RestClient.post 'http://192.168.33.10:8085//api/v1/tweets/new', {contents: msg, user_id: usr, hashtags: hashtags.to_json, mentions: mentions.to_json}
  resp_hash = JSON.parse(response)
  #byebug
  if resp_hash['saved'] == 'true'
    redirect PREFIX + '/'
  else
    @error = 'Tweet could not be saved'
    redirect PREFIX + '/'
  end
end

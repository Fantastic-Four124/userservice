require 'sinatra'
require 'sinatra/activerecord'
require 'byebug'
require 'faker' # fake people showing fake love
require_relative 'models/user'
require_relative 'models/hashtag'
require_relative 'models/mention'
require_relative 'models/tweet'
require_relative 'models/follow'
require_relative 'models/hashtag_tweets'
require_relative './version'

# name: testuser
# email: testuser@sample.com
# password: “password”

# /test/reset/all                   OJBK
# /test/reset/testuser              OJBK
# /test/version                     OJBK
# /test/status                      OJBK
# /test/reset/standard?             ojbk
# /test/users/create?               ?
# /test/user/u/tweets?count=t       X
# /test/user/u/follow?count=n       X
# /test/user/follow?count=n         X

### Vars
TESTUSER_NAME = 'testuser'
TESTUSER_EMAIL = 'testuser@sample.com'
TESTUSER_PASSWORD = 'password'
NUMBER_OF_SEED_USERS = 1000
TESTUSER_ID = 3456 # The test user will always have 3456
RETRY_LIMIT = 15
### Vars

### Helper Methods
### Helper Methods
### Helper Methods
def recreate_testuser
  result = User.new(id: TESTUSER_ID, username: TESTUSER_NAME, password: TESTUSER_PASSWORD, email:TESTUSER_EMAIL).save
  puts "Recreate testuser -> #{result}"
end

# Danger Zone! It will remove everthing in the DB
def clear_all()
  User.destroy_all
  Hashtag.destroy_all
  Mention.destroy_all
  Tweet.destroy_all
  Follow.destroy_all
  # Hashtag_tweets.destroy_all
end

# What happen when you break up with someone.... ;(
def remove_everything_about_testuser
  list_of_activerecords = [
    Follow.find_by(leader_id: TESTUSER_ID),
    Follow.find_by(user_id: TESTUSER_ID),
    Mention.find_by(username: TESTUSER_NAME),
    Tweet.find_by(user_id: TESTUSER_ID),
    User.find_by(username: TESTUSER_NAME)
  ]
  list_of_activerecords.each { |ar| destroy_and_save(ar) }
end

# Helper method, for active record object ONLY!
def destroy_and_save(active_record_object)
  return if active_record_object == nil
  active_record_object.destroy
  active_record_object.save
end

def report_status
  status = {
    'number of users': User.count,
    'number of tweets': Tweet.count,
    'number of follow': Follow.count,
    'Id of Test user': TESTUSER_ID
  }
  status
end

def generate_code(number)
  charset = Array('A'..'Z') + Array('a'..'z')
  Array.new(number) { charset.sample }.join
end

def get_fake_password
  str = [true, false].sample ? Faker::Fallout.character : ''
  str += str + ([true, false].sample ? Faker::Food.dish  : '')
  str += ([true, false].sample ? Faker::Kpop.boy_bands : '')
  str.gsub(/\s/, '')
end

# Calling this will prevent activerecord from assigning the same id (which violates constrain)
def reset_db_peak_sequence
  ActiveRecord::Base.connection.tables.each do |t|
    ActiveRecord::Base.connection.reset_pk_sequence!(t)
  end
end

def make_fake_tweets(user_ids, num)
  result = {}
  while num.positive?
    txts = [
      Faker::Pokemon.name + ' uses ' + Faker::Pokemon.move,
      Faker::SiliconValley.quote,
      Faker::SiliconValley.motto,
      Faker::ProgrammingLanguage.name + ' is the best!',
      'I went to ' + Faker::University.name + '.',
      'Lets GO! ' + Faker::Team.name
    ]
    msg = txts.sample
    usr_id = user_ids.sample
    new_tweet = Tweet.new(user_id: usr_id, message: msg)
    if new_tweet.save
      result[usr_id] = msg
      $redis.lpush('global', new_tweet.id)                # Cache it
      $redis.rpop('global') if $redis.llen('global') > 50 # Cache it
    else
      puts 'Fake tweet Failed.'
    end
    num -= 1
  end
  return result
end
### Helper Methods
def follower_follow_leader(follower_id,leader_id)
  link = Follow.find_by(user_id: follower_id, leader_id: leader_id)
  if link.nil?
      relation = Follow.new
      relation.user_id = follower_id
      relation.leader_id = leader_id
      relation.follow_date = Time.now
      relation.save

      follower = User.find(follower_id)
      leader = User.find(leader_id)

      follower.number_of_leaders = 0 if follower.number_of_leaders == nil
      leader.number_of_followers = 0 if leader.number_of_followers == nil

      follower.number_of_leaders += 1
      leader.number_of_followers += 1
      follower.save
      leader.save

      return relation
    end
end
### Helper Methods
### Helper Methods


post '/test/reset/all' do
  clear_all
  recreate_testuser
  report_status.to_json
end

post '/test/reset/testuser' do
  remove_everything_about_testuser
  recreate_testuser
  report_status.to_json
end

# Report the current version
get '/test/version' do
  "Version: #{Version.VERSION}".to_json
end

# One page report
# How many users, follows, and tweets are there. What is the TestUser’s id
get '/test/status' do
  st = report_status
  st.to_json
end

# Read from seed
# correct format should be /test/reset/standard?tweets=6
post '/test/reset/standard?' do
  puts params
  input = params[:tweets]
  clear_all

  if params.length == 1
    num = -1 # -1 means no limit
  else
    num = Integer(input) # only load n tweets from seed data
    if num <= 0
      raise ArgumentError, 'Argument is smaller than zero'
    end
  end
  users_hashtable = Array.new(NUMBER_OF_SEED_USERS + 1) # from user_id to user_name
  users_hashtable[0] = TESTUSER_NAME

  # make all new users
  File.open('./seeds/users.csv', 'r').each do |line|
    str = line.split(',')
    uid = Integer(str[0]) # ID provided in seed, useless for our implementation for now
    name = str[1].gsub(/\n/, "")
    name = name.gsub(/\r/, "")
    pw = get_fake_password
    users_hashtable[uid] = name
    i = RETRY_LIMIT
    while !User.new(id: uid, username: name, password: pw).save
      break if i.negative?
      puts "Entering user: #{name}, id: #{uid} failed, and retry."
      i -= 1
    end
  end
  # make all new users
  puts 'users done'

   # follow
   File.open('./seeds/follows.csv', 'r').each do |line|
    str = line.split(',')
    id1 = Integer(str[0]) # ID provided in seed, useless for our implementation for now
    id2 = Integer(str[1])
    puts "#{id1} fo #{id2}"
    follower_follow_leader(id1, id2)
  end
  # follow
  puts 'following done'

  # post all tweets
  File.open('./seeds/tweets.csv', 'r').each do |line|
    break if num == 0 # enforce a limit if there is one
    str = line.split(',')
    id = Integer(str[0])
    text = str[1]
    time_stamp = str[2]
    i = RETRY_LIMIT
    while !Tweet.new(user_id: id, message: text, timestamps: time_stamp).save
      break if i.negative?
      puts "Entering tweet: #{text}, by: #{id} #{users_hashtable[id]} failed and retry."
      i -= 1
    end
    num -= 1
  end
  # post all tweets

  recreate_testuser
  reset_db_peak_sequence # reset sequence
  result = { 'Result': 'GOOD!', 'status': report_status }
  result.to_json

end

# create u (integer) fake Users using faker. Defaults to 1.
# each of those users gets c (integer) fake tweets. Defaults to zero.
# Example: /test/users/create?count=100&tweets=5
post '/test/users/create?' do
  reset_db_peak_sequence # reset sequence
  input_count = params[:count]
  input_tweet = params[:tweets]
  count = Integer(input_count)
  tweet = Integer(input_tweet)
  puts 'Done faking users'
  # Fake tweets
  users_ids = Array.new(count)
  new_ppl = {}
  while count.positive?
    fake_ppl = Faker::Name.first_name + Faker::Name.last_name + generate_code(5)
    neo = User.new(username: fake_ppl, password: get_fake_password)
    if neo.save
      users_ids[count - 1] = neo.id
      new_ppl[neo.id] = fake_ppl
      puts neo.id
    end
    count -= 1
  end

  # Fake tweets
  result = {
    'New Fake Users': new_ppl,
    'New Fake Tweets': make_fake_tweets(users_ids, tweet),
    'Report': report_status
  }
  puts result
  result.to_json
end



# user u generates t(integer) new fake tweets
# /test/user/22/follow?count=10
post '/test/user/:user/tweets?' do
  puts params
  input_user = params[:user] # who
  input_user = TESTUSER_ID if input_user == 'testuser'
  input_count = params[:tweets]
  input_count = params[:count] if input_count == nil
  count = Integer(input_count) # number of fake tweets needed to generate
  result = {
    'New Fake Tweets': make_fake_tweets([input_user], count),
    'Report': report_status
  }
  result.to_json
end

# user u randomly follows people
# example: /test/user/22/follow?count=10
post '/test/user/:user/follows?' do
  puts params
  input_user = params[:user] # who
  input_user = TESTUSER_ID if input_user == 'testuser'
  input_count = params[:count]
  count = Integer(input_count) # number of fake follow needed to generate
  fos = []
  while count.positive?
    leader = User.order("RANDOM()").first.id
    puts leader
    puts input_user
    follower_follow_leader(Integer(input_user), leader)
    fos << leader
    count -= 1
  end
  result = {
    "User #{input_user} follows": fos,
    'Report': report_status
  }
  result.to_json
end

# people randomly follow each others
# example: /test/user/follow?count=10
post '/test/user/follows?' do
  puts params
  input_count = params[:count]
  count = Integer(input_count) # number of fake follow needed to generate
  fos = []
  while count.positive?
    leader = User.order('RANDOM()').first.id
    user = User.order('RANDOM()').first.id
    if user == leader
      leader = User.order('RANDOM()').first.id
      user = User.order('RANDOM()').first.id
    end
    follower_follow_leader(user, leader)
    fos << "#{user} follows #{leader}"
    count -= 1
  end
  result = {
    "Social Activities": fos,
    'Report': report_status
  }
  result.to_json
end

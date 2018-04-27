class UserHelper

  # When a user is created, we put some user info on redis so that we can check it later when user logs in.
  # The key info includes id,username, and bcrypted password
  def create_user_log(user)
    user_log = Hash.new
    user_log["password"] = user.password
    user_log["id"] = user.id.to_s
    u_hash = user.as_json
    u_hash['id'] = u_hash['id'].to_s
    $redis.set user.id, u_hash.to_json
    $redis.set user.username, user_log.to_json
    return user_log
  end

  # Check userinfo on redis
  def redis_login(id,username)
    user_hash = Hash.new
    token = SecureRandom.hex
    tokenized(user_hash,token,id,username)
    u_hash = JSON.parse($redis.get(id))
    u_hash['leaders'] = JSON.parse($redis_follow.get(id.to_s + ' leaders')).keys if $redis_follow.get(id.to_s + ' leaders')
    u_hash['id'] = u_hash['id'].to_s
    if u_hash['leaders'].nil?
        u_hash['leaders'] = []
        user = User.find(id)
        user.leaders.each {|l| u_hash['leaders'].push l.id.to_s}
    end
    return {user: u_hash, token: token}
  end

  # Create token for user and store the key user information on redis
  def tokenized(user_hash,token,id,username)
    user_hash["id"] = id
    user_hash["username"] = username
    $redis.set token, user_hash.to_json
    $redis.expire token, 432000
  end

  # If user info is not found in redis, we check database
  def database_login(user)
    token = SecureRandom.hex
    user_hash = Hash.new
    tokenized(user_hash,token,user.id,user.username)
    u_hash = user.as_json
    u_hash['leaders'] = []
    u_hash['id'] = u_hash['id'].to_s
    user.leaders.each {|l| u_hash['leaders'].push l.id.to_s}
    return {user: u_hash, token: token}
  end

  # Calling this will prevent activerecord from assigning the same id (which violates constrain)
  def reset_db_peak_sequence
    ActiveRecord::Base.connection.tables.each do |t|
      ActiveRecord::Base.connection.reset_pk_sequence!(t)
    end
  end

end

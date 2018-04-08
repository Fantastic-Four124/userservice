post PREFIX + "/user/:user_id/unfollow" do
    follower_id = session[:user_id]
    leader_id = params['user_id'].to_i
    uncheck = follower_unfollow_leader(follower_id,leader_id)
    if !uncheck
        redirect PREFIX + "/user/#{params['user_id']}"
    else
        redirect PREFIX + "/user/#{params['user_id']}"
    end
end

def follower_unfollow_leader(follower_id,leader_id)
  link = Follow.find_by(user_id: follower_id, leader_id: leader_id)
  if !link.nil?
      Follow.delete(link.id)

      follower = User.find(follower_id)
      leader = User.find(leader_id)

      return if follower.number_of_leaders.nil? || leader.number_of_followers.nil?

      follower.number_of_leaders -= 1
      leader.number_of_followers -= 1
      follower.save
      leader.save

      return Follow.find_by(user_id: follower_id, leader_id: leader_id)
    end
end

post PREFIX + "/user/:user_id/follow" do
    follower_id = session[:user_id]
    leader_id = params['user_id'].to_i
    check = follower_follow_leader(follower_id,leader_id)
    if check
        redirect PREFIX + "/user/#{params['user_id']}"
    else
        'repeated follow'
    end
end

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

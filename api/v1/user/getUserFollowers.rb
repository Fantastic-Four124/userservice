get PREFIX + '/user/:user_id/followers' do
  if protected!
    #TODO: implement followers/leaders; right now using user #2 as dummy
    @curr_user = User.find(params['user_id'])
    #follower_list = @curr_user.followers
    @user_list = @curr_user.followers
    #@user_list << follower
    @title = 'Followers'
    erb :user_list
  else
    redirect PREFIX + '/'
  end
end

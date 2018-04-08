get PREFIX + '/user/:user_id/leaders' do
  if protected!
    #TODO: implement followers/leaders; right now using user #2 as dummy
    @curr_user = User.find(params['user_id'])
    #leader_list = @curr_user.leaders
    @user_list = @curr_user.leaders
    #@user_list << follower
    @title = 'Leaders'
    erb :user_list
  else
    redirect PREFIX + '/'
  end
end

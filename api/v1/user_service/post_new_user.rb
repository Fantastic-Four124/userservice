def post_new_user(raw_result)
  hydrate_result = JSON.parse(raw_result)
  username = hydrate_result['username']
  password = hydrate_result['password']
  @user = User.new(username: username)
  @user.password = password
  @user.number_of_followers = 0
  @user.number_of_leaders = 0
  feedback = ""
  if @user.save
    feedback = "register #{username} Successful"
  else
    feedback = "register #{username} Fail"
  end
end

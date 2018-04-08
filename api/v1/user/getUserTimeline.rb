get PREFIX + '/user/:user_id/timeline' do
  if protected!
    @curr_user = User.find(params['user_id'])
    leader_list = @curr_user.leaders
    tweets = []
    leader_list.each do |leader|
      subtweets = Tweet.where("user_id = '#{leader.id}'")
      tweets.push(*subtweets)
    end
    tweets.sort_by &:created_at
    tweets.reverse!
    @tweets = tweets[0..49]
    erb :tweet_feed
  else
    redirect PREFIX + '/'
  end
end

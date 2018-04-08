get PREFIX + '/hashtag/:hashtag_id' do
  @curr_user = session[:user_hash]
  @no_term = false
  all_tweet_ids = HashtagTweet.where(:hashtag_id => params['hashtag_id']).pluck(:tweet_id)
  @results = Tweet.where(id: all_tweet_ids).sort_by &:created_at
  @results.reverse!
  @user_search = false
  erb :search_results
end

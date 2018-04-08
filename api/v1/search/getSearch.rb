get PREFIX + '/search' do
  @curr_user = session[:user_hash]
  term = params[:search]
  if term
    @no_term = false
    if /([@.])\w+/.match(term)
      term = term[1..-1]
      @results = User.where("username like ?", "%#{term}%")
      @user_search = true
    else
      @results = Tweet.where("message like ?", "%#{term}%").sort_by &:created_at
      @results.reverse!
      @user_search = false
    end
  else
    @no_term = true
    @results = []
  end
  erb :search_results
end

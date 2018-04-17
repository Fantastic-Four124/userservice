post '/test/reset/all' do
  clear_all
  recreate_testuser(params)
end

post '/test/reset/testuser' do
  remove_everything_about_testuser(params['username'])
  recreate_testuser(params)
end


def recreate_testuser(params)
  result = User.new(id: params['user_id'], username: params['username'], password: params['password'], email:params['email']).save
end

def clear_all()
  User.destroy_all
end

def remove_everything_about_testuser(testuser_name)
  list_of_activerecords = [
    User.find_by(username: testuser_name)
  ]
  list_of_activerecords.each { |ar| destroy_and_save(ar) }
end

def destroy_and_save(active_record_object)
  return if active_record_object == nil
  active_record_object.destroy
  active_record_object.save
end

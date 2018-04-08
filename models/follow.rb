class Follow < ActiveRecord::Base
  include ActiveRecord::Calculations
    validates :user_id,presence:true
    validates :leader_id,presence:true

    belongs_to :user
    belongs_to :leader, class_name: 'User'
end

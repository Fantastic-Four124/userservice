class Follow < ActiveRecord::Base
  include ActiveRecord::Calculations
    validates :user_id,presence:true
    validates :leader_id,presence:true
    validates :user_id, uniqueness: { scope: :leader_id }

    belongs_to :user
    belongs_to :leader, class_name: 'User'
end

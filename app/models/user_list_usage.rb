# == Schema Information
#
# Table name: user_list_usages
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  list_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

class UserListUsage < ActiveRecord::Base
  belongs_to :user
  belongs_to :list
  
  validates :user, presence: true
  validates :list, presence: true
end

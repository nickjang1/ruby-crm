# == Schema Information
#
# Table name: tags
#
#  id                :integer          not null, primary key
#  type              :string(255)
#  name              :string(255)
#  unboxed_countable :boolean
#  parent_id         :integer
#  position          :integer
#  created_at        :datetime
#  updated_at        :datetime
#  property_id       :integer
#

class List < Tag
	has_many :user_list_usages

  default_scope { where(property_id: Property.current_id) }
  
  def self.top_six_for_user(user)
    lists = List.all

    # Get all lists ids that have been used to create orders and sort them by their use frequency
    sorted_lists_ids = UserListUsage.where(user_id: user.id).group(:list_id).count.sort_by{|key, value| -value}.map(&:first)
    
    # Model.find([3,2,1]) won't return records in the order that you specified the ids. This achieves that.
    sorted_lists = sorted_lists_ids.map{|id| lists.detect{|list| list.id == id}}
    sorted_lists.concat(lists).uniq[0..5].compact
  end
end

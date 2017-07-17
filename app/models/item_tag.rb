# == Schema Information
#
# Table name: item_tags
#
#  item_id  :integer
#  tag_id   :integer
#  tag_type :string(255)
#  id       :integer          not null, primary key
#

class ItemTag < ActiveRecord::Base
  belongs_to :tag
  belongs_to :item

  validates :tag_id, uniqueness: {scope: :item_id}
end

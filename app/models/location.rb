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

class Location < Tag
end

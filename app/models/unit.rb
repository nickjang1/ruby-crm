# == Schema Information
#
# Table name: units
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

class Unit < ActiveRecord::Base
  has_many :items
  validates :name, presence: true, uniqueness: true

  def to_s
    self.name
  end
end

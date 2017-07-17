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

class Category < Tag
  has_and_belongs_to_many :departments
  has_many :budgets, dependent: :destroy

  def self.maintenance
    Category.find_by(name: 'Maintenance')
  end
end

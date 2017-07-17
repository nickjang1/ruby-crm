
class Budget < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :category

  validates :amount, presence: true

  default_scope { where(category_id: Category.pluck(:id)) }
  
end

class Maintenance::Material < ActiveRecord::Base
  belongs_to :work_order, class_name: 'Maintenance::WorkOrder', foreign_key: :work_order_id
  belongs_to :item

  validates :item, :work_order, :price, :quantity, presence: true

  default_scope { order(created_at: :desc) }

  def cost
    quantity.to_f * price.to_f
  end
end
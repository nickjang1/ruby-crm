# == Schema Information
#
# Table name: item_requests
#
#  id                  :integer          not null, primary key
#  purchase_request_id :integer
#  item_id             :integer
#  quantity            :decimal(, )
#  count               :decimal(, )
#  part_count          :decimal(, )
#  created_at          :datetime
#  updated_at          :datetime
#  skip_inventory      :boolean
#

class ItemRequest < ActiveRecord::Base
  belongs_to :purchase_request
  belongs_to :item
  has_many :purchase_orders
  has_one :item_transaction, as: :purchase_step, dependent: :destroy
  has_one :item_order

  validates_numericality_of :quantity, greater_than_or_equal_to: 0, allow_nil: true
  validates_presence_of :item
  accepts_nested_attributes_for :purchase_orders

  delegate :price_unit_factor, to: :item
  delegate :purchase_unit_factor, to: :item

  before_update :set_prev_quantity

  def total_item_price
    (self.quantity || 0) * self.item.price.to_f * self.price_unit_factor
  end

  def order_quantity
    offset = [item.par_level.to_f - self.count.to_f, 0].max
    offset = 0 if self.count.nil?

    (self.purchase_unit_factor * offset).ceil
  end
  
  def order_number
    self.item_order.purchase_order.number if self.purchase_request.ordered?
  end

  def set_prev_quantity
    self.prev_quantity = self.quantity_was# if quantity_changed?
  end

end

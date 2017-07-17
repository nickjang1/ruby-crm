# == Schema Information
#
# Table name: item_receipts
#
#  id                  :integer          not null, primary key
#  purchase_receipt_id :integer
#  item_order_id       :integer
#  item_id             :integer
#  quantity            :decimal(, )
#  price               :decimal(, )
#  created_at          :datetime
#  updated_at          :datetime
#

class ItemReceipt < ActiveRecord::Base
  belongs_to :purchase_receipt
  belongs_to :item_order
  belongs_to :item
  has_one :item_transaction, as: :purchase_step, dependent: :destroy

  validates_numericality_of :quantity, greater_than: 0, allow_nil: true

  after_save :assign_transaction

  delegate :price_unit_factor, to: :item
  delegate :purchase_unit_factor, to: :item

  def item_order=(item_order)
    item_order = ItemOrder.find(item_order) unless item_order.kind_of? ItemOrder

    self.item_order_id = item_order.id
    self.item_id = item_order.item_id
    self.quantity = item_order.pending
    #TODO: Consider using item's price instead (last known price, so previous receipts will update price)
    self.price = item_order.price
  end

  # Fall back to the item order item if there's no item defined
  def item
    super || item_order.item
  end

  def total
    Money.new(price * 100 * quantity * self.price_unit_factor, PurchaseOrderDecorator::CURRENCY)
  end

  private

  def assign_transaction
    change = {change: self.quantity}
    if item_transaction.blank?
      self.create_item_transaction(change)
    else
      self.item_transaction.update_attributes(change)
    end
  end
end

# == Schema Information
#
# Table name: item_orders
#
#  id                :integer          not null, primary key
#  purchase_order_id :integer
#  item_id           :integer
#  item_request_id   :integer
#  quantity          :decimal(, )
#  price             :decimal(, )
#  created_at        :datetime
#  updated_at        :datetime
#

class ItemOrder < ActiveRecord::Base
  belongs_to :purchase_order
  belongs_to :item
  belongs_to :item_request
  has_many :item_receipts

  validates :purchase_order, presence: true
  validates :item, presence: true
  validates :item_request, presence: true

  validates_numericality_of :quantity, greater_than: 0, allow_nil: true

  delegate :price_unit_factor, to: :item
  delegate :purchase_unit_factor, to: :item

  def received
    self.item_receipts.sum :quantity
  end

  def pending
    [self.quantity - received, 0].max
  end

  def percent_complete
    received / self.quantity.to_f * 100
  end

  def complete?
    pending.zero?
  end

  def average_price
    return price unless item_receipts.present?

    total_paid_for_reciepts = item_receipts.map{|ir| ir.quantity * ir.price}.reduce(&:+)
    total_paid_for_reciepts / received
  end

  def sku
    self.purchase_order.vendor.vendor_items.where("vendor_items.item_id = ?", self.item.id).first.sku unless self.item.nil?
  end

  def total
    average_price * quantity * self.price_unit_factor
  end

  def original_total
    price * quantity
  end
end

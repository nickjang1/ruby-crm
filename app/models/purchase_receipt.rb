# == Schema Information
#
# Table name: purchase_receipts
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  purchase_order_id :integer
#  created_at        :datetime
#  updated_at        :datetime
#  freight_shipping  :decimal(, )
#  property_id       :integer

class PurchaseReceipt < ActiveRecord::Base
  belongs_to :user
  belongs_to :purchase_order
  belongs_to :property
  has_many :item_receipts


  # TODO: Revise this! Originally:
  # attributes[:quantity].blank? or attributes[:quantity].zero?
  # New: attributes[:quantity].to_f.zero?
  # nil.to_f == 0, "".to_f == 0, String.zero? => NoMethodError
  accepts_nested_attributes_for :item_receipts, reject_if: proc {|params| params[:quantity].to_f.zero?}

  validates :user, :purchase_order, presence: true

  scope :include_items, -> (item_ids) { PurchaseReceipt.includes(:item_receipts).where("item_receipts.item_id = any(array#{item_ids})").references(:item_receipts) }
  default_scope { where(property_id: Property.current_id) }

  def user
    User.with_deleted.find(self.user_id)
  end
  
  def purchase_order=(purchase_order)
    self.purchase_order_id = purchase_order.id
    purchase_order.item_orders.order(item_id: :desc).each do |item_order|
      self.item_receipts.build item_order: item_order 
    end
  end

  def is_first?
    purchase_order.purchase_receipts.empty? || purchase_order.purchase_receipts.first == self 
  end

  def total item_ids = []
    # Money.new(item_receipts.sum('quantity * price') * 100)
    receipts = item_ids.blank? ? item_receipts : item_receipts.where("item_receipts.item_id = any(array#{item_ids})")
    receipts.reduce(Money.new(0, PurchaseOrderDecorator::CURRENCY)) do |total, item_receipt|
      total += item_receipt.total
    end
  end

  def total_w_freight
    total + Money.new(freight_or_zero * 100)
  end

  def freight_or_zero
    freight_shipping || 0
  end
end

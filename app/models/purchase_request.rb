# == Schema Information
#
# Table name: purchase_requests
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  created_at  :datetime
#  updated_at  :datetime
#  state       :string(255)
#  property_id :integer
#

class PurchaseRequest < ActiveRecord::Base
  include PusherHelper
  # This default should be switched up later if we internationalize this app
  # A more reasonable scheme would probably be to store currency preference
  # with each property.
  CURRENCY = 'USD'

  belongs_to :user
  belongs_to :property
  has_many :item_requests, dependent: :destroy
  has_many :items, :through => :item_requests
  has_many :vendors, -> { uniq }, :through => :items
  has_many :preferred_vendors, -> { uniq.where('vendor_items.preferred = ?', true) }, through: :items, source: :vendors
  has_many :purchase_orders
  has_many :messages, as: :messagable

  accepts_nested_attributes_for :item_requests, allow_destroy: true

  validates :user, presence: true

  STATES = [:inventory, :request, :completed, :inventory_finished]

  #FIXME find some where else to put the view level concerns
  BTN_CLASS = {inventory_finished: 'btn-default', inventory: 'btn-default', request: 'btn-primary', completed: 'btn-success', approved: 'btn-warning', ordered: 'btn-info' }
  BTN_ICON = { inventory: 'ico-marker2', request: 'ico-basket2', completed: 'ico-cart-checkout', approved: 'ico-shopping-cart', ordered: 'ico-eye' }
  BADGE_CLASS = { inventory: 'badge-inverse', request: 'badge-primary', completed: 'badge-success', approved: 'badge-primary', ordered: 'btn-primary' }

  ACTION = {
    inventory: 'Count',
    request: 'Request',
    completed: 'Approve',
    approved: 'Order'
  }

  scope :without_inventory_finished, ->{ where{state != 'inventory_finished'} }
  default_scope { where(property_id: Property.current_id) }

  def number
    '#%05d' % self.id unless self.new_record?
  end

  state_machine initial: :inventory do
    after_transition :on => :approve, :do => :create_transaction

    event :finish do
      transition inventory: :inventory_finished#, request: :completed
    end

    event :next do
      transition inventory: :request, request: :completed
    end

    event :commit do
      transition inventory: :inventory, request: :request
    end

    event :back do
      transition request: :inventory
    end

    event :reject do
      transition completed: :inventory
    end

    event :approve do
      transition completed: :approved
    end

    event :create_orders do
      transition approved: :ordered
    end    
  end

  def user
    User.with_deleted.find(self.user_id)
  end

  def total_price
    return 0 if self.item_requests.empty?

    requested_items = item_requests.where.not(quantity: nil)

    requested_items.reduce(Money.new(0, CURRENCY)) do |total, item_request|
      total += Money.new(100 * item_request.total_item_price, CURRENCY)
    end
  end

  def approval_request current_property, current_user
    approvers = current_property.proper_approvers self.total_price, current_user.id
    return false if approvers.blank?
    approver_ids = approvers.map(&:id)

    RequestApprovalWorker.perform_async(approvers.map(&:email), self.id, approver_ids)
    true
  end

  def approve_reject commit, original_id, current_user
    if commit == 'approve'
      RequestCheckWorker.perform_async(self.id, original_id, 'approved', current_user.name)
    elsif commit == 'reject'
      RequestCheckWorker.perform_async(self.id, original_id, 'rejected', current_user.name)
    end
  end

  def items_by_vendor
    self.item_requests.where{quantity != nil}.group_by{ |ir| ir.item.vendors.first }
  end
  
  def order_count
    self.purchase_orders.count if self.ordered?
  end
  
  def order_numbers
    self.purchase_orders.map(&:number).join(', ') if self.ordered?
  end

  def create_orders_on_approval!(current_user, current_property)
    items_by_vendor.each do |vendor, items_requests|
      purchase_order = PurchaseOrder.create(
        user: current_user,
        property: current_property,
        vendor: vendor,
        purchase_request_id: self.id,
        state: :open
      )

      items_requests.each do |items_request|
        preferred_item = items_request.item.vendor_items.preferred.first
        price = preferred_item.nil? ? items_request.item.vendor_items.first.price : preferred_item.price
        purchase_order.item_orders.create(
          item: items_request.item,
          item_request: items_request,
          quantity: items_request.quantity,
          price: price
        )
      end

    end
    self.create_orders # change state to ordered
  end

  def quantities_changed?
    item_requests.map(&:quantity_changed?).any?
  end

  private

  def create_transaction
    for request in self.item_requests
      request.create_item_transaction!(change: request.count  - (request.item.count || 0)) unless request.count.nil?
    end
  end

end

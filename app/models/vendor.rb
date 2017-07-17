# == Schema Information
#
# Table name: vendors
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  street_address  :string(255)
#  zip_code        :string(255)
#  city            :string(255)
#  email           :string(255)
#  phone           :string(255)
#  fax             :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  contact_name    :string(255)
#  shipping_method :string(255)
#  shipping_terms  :string(255)
#

class Vendor < ActiveRecord::Base
  has_many :vendor_items, dependent: :destroy
  has_many :items, through: :vendor_items
  has_many :purchase_orders
  has_many :purchase_receipts, through: :purchase_orders
  belongs_to :property

  has_one :procurement_interface
  accepts_nested_attributes_for :procurement_interface

  validates :name, presence: true

  validates :street_address, presence: true, if: :address_present?
  validates :city, presence: true, if: :address_present?
  validates :zip_code, presence: true, if: :address_present?

  validates :email, email: true, allow_blank: true

  before_destroy :check_for_purchase_orders

  scope :top, -> (n){order(total_spent: :desc).limit(n) }
  default_scope { where(property_id: Property.current_id) }

  def address_present?
    self.street_address.present? || self.city.present? || self.zip_code.present?
  end

  def to_s
    self.name
  end

  def total_spent
    #FIXME: @hugo shouldn't use a decorator from inside a model
    @total_spent ||= PurchaseOrderDecorator.decorate_collection(purchase_orders.closed).map(&:total_price).reduce(:+)
    @total_spent || 0
  end

  def default_address
    if address_present?
      "#{self.street_address} #{self.city} #{self.zip_code}"
    else
      '-'
    end
  end

  def procurement_interface_enabled?(interface_type)
    procurement_interface && procurement_interface.interface_type.present? && procurement_interface.interface_type == interface_type.to_s
  end
  
  private
  def check_for_purchase_orders
    if purchase_orders.count > 0
      errors.add :base, 'cannot delete vendor while purchase orders exist'
      return false
    end
  end
end

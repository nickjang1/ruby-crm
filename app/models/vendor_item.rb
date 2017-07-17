# == Schema Information
#
# Table name: vendor_items
#
#  id             :integer          not null, primary key
#  preferred      :boolean
#  items_per_box  :decimal(, )
#  vendor_id      :integer
#  item_id        :integer
#  box_unit_id    :integer
#  created_at     :datetime
#  updated_at     :datetime
#  price_cents    :integer          default(0), not null
#  price_currency :string(255)      default("USD"), not null
#

class VendorItem < ActiveRecord::Base
  monetize :price_cents, allow_nil: false
  belongs_to :vendor
  belongs_to :item
  belongs_to :box_unit, class_name: 'Unit'

  validates :vendor, presence: true

  scope :preferred, -> {where preferred: true}
end

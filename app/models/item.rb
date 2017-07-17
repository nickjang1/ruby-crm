# == Schema Information
#
# Table name: items
#
#  id                      :integer          not null, primary key
#  name                    :string(255)
#  count                   :decimal(, )
#  frequency               :integer
#  par_level               :decimal(, )
#  image_file_name         :string(255)
#  image_content_type      :string(255)
#  image_file_size         :integer
#  image_updated_at        :datetime
#  item_transactions_count :integer          default(0)
#  created_at              :datetime
#  updated_at              :datetime
#  unit_id                 :integer
#  subpack_unit_id         :integer
#  pack_unit_id            :integer
#  unit_subpack            :float
#  subpack_size            :float
#  inventory_unit_id       :integer
#  price_unit_id           :integer
#  property_id             :integer
#  is_taxable              :boolean
#  archived                :boolean          default(FALSE)
#  description             :text
#  is_asset                :boolean
#  purchase_cost           :decimal(, )
#  purchase_cost_unit_id   :integer
#  pack_size               :decimal(, )
#  brand_id                :integer
#

class Item < ActiveRecord::Base
  include PgSearch

  belongs_to :property
  belongs_to :unit
  belongs_to :subpack_unit, class_name: 'Unit'
  belongs_to :pack_unit, class_name: 'Unit'
  belongs_to :inventory_unit, class_name: 'Unit'
  belongs_to :price_unit, class_name: 'Unit'
  belongs_to :purchase_cost_unit, class_name: 'Unit'
  has_many :item_tags, dependent: :destroy
  has_many :tags, through: :item_tags
  has_and_belongs_to_many :categories, association_foreign_key: 'tag_id', join_table: 'item_tags'
  has_and_belongs_to_many :locations, association_foreign_key: 'tag_id', join_table: 'item_tags'
  has_and_belongs_to_many :lists, association_foreign_key: 'tag_id', join_table: 'item_tags'
  has_many :item_transactions
  has_many :item_requests
  has_many :item_orders
  has_many :purchase_orders, through: :item_orders
  has_many :purchase_requests, through: :item_requests
  has_many :vendor_items
  has_many :item_orders
  has_many :item_receipts
  has_many :vendors, through: :vendor_items
  has_attached_file :image, styles: {medium: '300x300#', thumb: '100x100#'}
  has_many :transactions, class_name: 'ItemTransaction'
  belongs_to :brand

  accepts_nested_attributes_for :unit, reject_if: proc {|attributes| attributes[:name].blank?}
  accepts_nested_attributes_for :pack_unit, reject_if: proc {|attributes| attributes[:name].blank?}
  accepts_nested_attributes_for :subpack_unit, reject_if: proc {|attributes| attributes[:name].blank?}
  accepts_nested_attributes_for :vendor_items, allow_destroy: true

  validates :vendor_items, :name, :unit, presence: true
  validates :inventory_unit, :price_unit, presence: true
  validates :property, associated: true

  validate :at_least_one_category
  def at_least_one_category
    errors.add :category_ids, 'at least one should be selected' if category_ids.count < 1
  end

  scope :active, -> {where archived: false}

  scope :under_tag, lambda { |tags, type|
    tag_ids = tags.map{|tag| tag.self_and_descendants.pluck(:id)}.flatten
    unless tags.empty?
      items = joins(:tags).where(tags: {id: tag_ids})
      if type.nil?
        items
      else
        items.where tags: {type: type}
      end
    end
  }
  scope :under_category, lambda {|categories| under_tag categories, 'Category'}
  scope :under_location, lambda {|locations| under_tag locations, 'Location'}
  scope :under_list, lambda {|lists| under_tag lists, 'List'}
  scope :for_user, lambda {|user| active.joins(:tags).where(tags: {id: Permission.allowed_tag_ids_for(user, :read)})}
  
  default_scope { where(property_id: Property.current_id) }
  
  after_create :set_item_number
  
  def set_item_number
    self.number = (Item.maximum(:number) || 9999) + 1
    self.save
  end

  def price
    vendor_items.first.try(:price) || 0
  end

  def has_countable_units?
    not tags.where(unboxed_countable: true).count.zero?
  end

  def self.destroy
    self.update_attribute :archived, true
  end

  def vendor_name
    (vendor_items.preferred.limit(1).first.try(:vendor) || vendors.first).try(:name)
  end

  pg_search_scope :search_columns, (lambda do |search_for, query|
    common_config = {
      using: {
        tsearch: { dictionary: "english", prefix: true } 
      },
      query: query
    }

    search_options = {
      all: {
        against: [:number, :name, :par_level],
        associated_against: { unit: [:name], vendors: [:name] }
      },
      number: { against: [:number] },
      name: { against: [:name] },
      unit: { associated_against: { unit: [:name] } },
      par: { against: [:par_level] },
      vendor: { associated_against: { vendors: [:name] } }
    }

    common_config.merge(search_options[search_for])
  end)

  def self.search_tree(q)
    q = q.dup rescue {}

    tags_id_eq_any = q.delete('tags_id_eq_any').reject &:blank? rescue []
    categories_id_eq_any = q.delete('categories_id_eq_any').reject &:blank? rescue []
    locations_id_eq_any = q.delete('locations_id_eq_any').reject &:blank? rescue []
    lists_id_eq_any = q.delete('lists_id_eq_any').reject &:blank? rescue []

    Item.active
      .under_tag(Tag.where(id: tags_id_eq_any), nil)
      .under_category(Category.where(id: categories_id_eq_any))
      .under_location(Location.where(id: locations_id_eq_any))
      .under_list(List.where(id: lists_id_eq_any))
      .search q
  end

  def number
    '%05d' % self[:number] unless self[:number].nil?
  end

  def vendor_number(vendor_id)
    vendor_items.where(vendor_id: vendor_id).first.try(:sku)
  end

  # factor for inventory unit to purchase unit
  def purchase_unit_factor
    return 1 if unit_id == inventory_unit_id
    return 1 / (pack_size || 1) if inventory_unit_id == pack_unit_id
    return 1 / (pack_size || 1) / (subpack_size || 1) if inventory_unit_id == subpack_unit_id
    1
  end

  # factor for purchase unit to price unit
  def price_unit_factor
    return 1 if unit_id == price_unit_id
    return pack_size || 1 if price_unit_id == pack_unit_id
    return (pack_size || 1) * (subpack_size || 1) if price_unit_id == subpack_unit_id
    return 1
  end

  def purchase_price
    purchase_cost.to_f * purchase_unit_factor
  end

  def pack_present?
    self.pack_unit.present? && self.pack_size.present? && self.pack_size > 0
  end

  def subpack_present?
    self.subpack_unit.present? && self.subpack_size.present? && self.subpack_size > 0
  end

  # Removes the decimal part from the given number string
  #
  # @param [String, Fixnum, Float] number The product number to be cleaned up
  # @return [String] The given +number+, sans decimal suffix
  def self.format_item_number(number)
    case number.class.to_s
    when 'String' then number
    when 'Fixnum' then number.to_s
    when 'Float' then number.to_i.to_s
    end
  end
end

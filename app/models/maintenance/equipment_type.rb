class Maintenance::EquipmentType < ActiveRecord::Base
  acts_as_paranoid
  include RankedModel
  ranks :row_order

  has_many :equipments, :class_name => 'Maintenance::Equipment', foreign_key: :equipment_type_id, dependent: :destroy
  has_many :active_equipments, -> { active }, :class_name => 'Maintenance::Equipment', foreign_key: :equipment_type_id, dependent: :destroy
  has_many :checklist_groups, -> { checklist_groups }, class_name: 'Maintenance::EquipmentChecklistItem', foreign_key: :equipment_type_id
  has_many :checklist_items, class_name: 'Maintenance::EquipmentChecklistItem', foreign_key: :equipment_type_id, dependent: :destroy
  has_one :attachment, class_name: 'Maintenance::Attachment', as: :attachmentable, dependent: :destroy

  scope :active, -> () { where(deleted_at: nil) }

  accepts_nested_attributes_for :attachment, :allow_destroy => true

  validates :name, presence: true

  def self.default_scope
    rank(:row_order).where(property_id: Property.current_id)
  end

  def self.for_work_order_select
    active.map { |etype| [etype.name, etype.equipments.active.pluck(:name, :id)] }
  end

  def name_with_units
    "#{self.name} (#{equipments.active.count} units)"
  end

end

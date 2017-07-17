class Maintenance::EquipmentChecklistItem < ActiveRecord::Base
  include RankedModel
  ranks :row_order, with_same: :group_id, column: :row_order

  FREQUENCIES = [
      ['Every Month', 1], ['Every 2 months', 2], ['Quarterly', 3],
      ['Every 4 months', 4], ['Twice a year', 6], ['Once a year', 12]
  ]

  belongs_to :user
  belongs_to :property
  belongs_to :equipment_type, class_name: 'Maintenance::EquipmentType', foreign_key: :equipment_type_id
  belongs_to :group, foreign_key: :group_id, inverse_of: :checklist_items, class_name: 'Maintenance::EquipmentChecklistItem'
  has_many :checklist_items, -> { rank(:row_order) }, foreign_key: :group_id, class_name: 'Maintenance::EquipmentChecklistItem', dependent: :destroy
  has_many :maintenance_records, class_name: 'Maintenance::MaintenanceRecord', foreign_key: :equipment_checklist_group_id

  validates :name, presence: true

  default_scope { where(property_id: Property.current_id) }
  scope :checklist_groups, -> { where(group_id: nil) }

  def frequency_text
    FREQUENCIES.select { |f| f[1] == self.frequency }[0][0]
  end

end
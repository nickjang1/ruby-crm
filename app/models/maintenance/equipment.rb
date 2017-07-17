class Maintenance::Equipment < ActiveRecord::Base
  include RankedModel
  ranks :row_order, with_same: :equipment_type_id, column: :row_order

  acts_as_paranoid

  belongs_to :property
  belongs_to :equipment_type, class_name: 'Maintenance::EquipmentType', foreign_key: :equipment_type_id
  has_one :attachment, class_name: 'Maintenance::Attachment', as: :attachmentable, dependent: :destroy
  has_many :maintenance_records, as: :maintainable

  accepts_nested_attributes_for :attachment, :allow_destroy => true

  validates :name, presence: true
  validates :location, presence: true
  validates_uniqueness_of :name, scope: [:property_id]

  scope :active, -> { where(deleted_at: nil) }

  def self.default_scope
    where(property_id: Property.current_id).rank(:row_order)
  end

  def to_s
    "#{name} (#{location})"
  end

  def start_maintenance(user, group_id)
    record = maintenance_records.where(equipment_checklist_group_id: group_id).last
    if record.nil? || record.status != Maintenance::MaintenanceRecord::STATUS_IN_PROGRESS.to_s
      record = maintenance_records.build
      record.equipment_checklist_group_id = group_id
    end
    record.user = user
    record.status = Maintenance::MaintenanceRecord::STATUS_IN_PROGRESS
    record.started_at = Time.now
    record.save
    record
  end

end

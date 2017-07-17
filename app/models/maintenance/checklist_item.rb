class Maintenance::ChecklistItem < ActiveRecord::Base
  include RankedModel
  ranks :area_row_order, scope: :room_areas, column: :row_order
  ranks :item_row_order, with_same: :area_id, scope: :item_active, column: :row_order
  ranks :public_area_row_order, with_same: :public_area_id, scope: :item_active, column: :row_order

  belongs_to :user
  belongs_to :property
  belongs_to :public_area, foreign_key: :public_area_id, :class_name => 'Maintenance::PublicArea'
  has_many :checklist_items, -> { rank(:item_row_order).where(is_deleted: false) }, foreign_key: :area_id, class_name: 'Maintenance::ChecklistItem'
  belongs_to :area, foreign_key: :area_id, inverse_of: :checklist_items, class_name: 'Maintenance::ChecklistItem'

  validates_presence_of :name, :maintenance_type

  default_scope { where(property_id: Property.current_id) }
  scope :by_type, -> (type) { where(maintenance_type: type) }
  scope :areas, -> { rank(:area_row_order).where(area_id: nil, is_deleted: false) }
  scope :room_areas, -> { areas.where(maintenance_type: :rooms) }
  scope :item_active, -> { where(is_deleted: false) }
  scope :deleted, -> {
    includes(:area)
      .where('areas_maintenance_checklist_items.is_deleted is NULL or
              areas_maintenance_checklist_items.is_deleted = true or
              maintenance_checklist_items.is_deleted = true')
      .references(:checklist_items)
  }
  scope :active, -> {
    includes(:area)
      .where('areas_maintenance_checklist_items.is_deleted is NULL or
              areas_maintenance_checklist_items.is_deleted = false')
      .where(is_deleted: false)
      .references(:checklist_items)
  }
  scope :for_public_areas, -> { where.not(public_area_id: nil).rank(:public_area_row_order) }
  scope :non_areas, -> { where.not(area_id: nil) }

  def self.areas_with_subcategories
    room_areas.map do |area|
      {id: area.id, name: area.name, subcategories: area.checklist_items.rank(:item_row_order).active.select([:id, :name])}
    end
  end

end

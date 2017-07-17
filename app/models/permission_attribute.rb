class PermissionAttribute < ActiveRecord::Base
  serialize :options

  has_many :permissions
  has_many :items, foreign_key: :parent_id, class_name: 'PermissionAttribute'
  belongs_to :parent, foreign_key: :parent_id, inverse_of: :items, class_name: 'PermissionAttribute'

  scope :roots, -> { where(parent_id: nil).order(created_at: :asc).includes(:items) }
  scope :access_attributes, -> { where(subject: :access) }
  scope :level2, -> { where(parent_id: roots.pluck(:id)) }
  scope :assignable, -> { where(subject: 'maintenance_work_order', action: :assignable) }
end

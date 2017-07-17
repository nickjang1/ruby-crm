class MagicTag < ActiveRecord::Base
  validates :name, presence: true
  validates :text, presence: true

  belongs_to :property
  belongs_to :created_by, class_name: 'User', foreign_key: :created_by_id

  default_scope { where(property_id: Property.current_id) }
end
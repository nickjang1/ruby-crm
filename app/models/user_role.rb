class UserRole < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :user
  belongs_to :role
  belongs_to :property

  validates :property_id, uniqueness: {scope: [:user_id, :deleted_at], message: "A user can only have one role per property" }
  validates :role_id, presence: true

  scope :active, -> { where(deleted_at: nil) }

  def self.default_scope
    where(property_id: Property.current_id, deleted_at: nil)
  end
end

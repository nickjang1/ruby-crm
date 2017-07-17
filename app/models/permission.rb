# == Schema Information
#
# Table name: permissions
#
#  id             :integer          not null, primary key
#  role_id        :integer
#  department_id  :integer
#  subject        :string(255)
#  action         :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#

class Permission < ActiveRecord::Base

  serialize :options

  belongs_to :role
  belongs_to :department
  belongs_to :property
  belongs_to :permission_attribute

  scope :permitted, -> (role_ids, department_ids) { where(role_id: role_ids, department_id: department_ids) }
  scope :by_attribute_subject, -> (subject) { includes(:permission_attribute).where(permission_attributes: { subject: subject.to_s } ) }
  scope :by_attribute_action, -> (action) { includes(:permission_attribute).where(permission_attributes: { action: action.to_s } ) }
  default_scope { where(property_id: Property.current_id) }

end

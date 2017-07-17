class ReportRun < ActiveRecord::Base
  belongs_to :user
  belongs_to :report
  belongs_to :property

  default_scope { where(property_id: Property.current_id) }
end

class Maintenance::Attachment < ActiveRecord::Base

  belongs_to :equipmentable, polymorphic: true
  mount_uploader :file, EquipmentAttachmentUploader

end

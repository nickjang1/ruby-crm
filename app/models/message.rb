class Message < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :messagable, polymorphic: true
  
  validates :user, presence: true
  validates :body, presence: true
  
  mount_uploader :attachment, MessageAttachmentUploader

  default_scope { order('created_at DESC') }
  
  def user_name
    user.try(:name)
  end
  
  def user_avatar
    user.avatar.thumb.url
  end

end

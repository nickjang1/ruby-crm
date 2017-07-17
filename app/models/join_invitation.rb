class JoinInvitation < ActiveRecord::Base
  belongs_to :sender, class_name: 'User'
  belongs_to :invitee, class_name: 'User'
  belongs_to :targetable, polymorphic: true

  serialize :params, Hash

  def target_type
    if targetable.is_a? Property
      'hotel'
    elsif targetable.is_a? Corporate
      'corporate'
    else
      'other'
    end
  end
end

module StampUser
  # ARAccountability Concern adds functions that help the applicaiton keep track of who is doing what
  # to various model objects.  This is a standard need for SAAS type applications.

  extend ActiveSupport::Concern

  included do
    # SentientUser gem allows us to make 'current_user' available to the model object.
    # Callbacks added to user stamp records up on create and update.
    include SentientUser
    before_save :stamp_updated_by
    before_create :stamp_created_by, :stamp_updated_by

    private

    # ActiveSupport's presence method required to aleviate migration complaints
    def stamp_created_by
      self.created_by = self.class.current.present? ? self.class.current.id : nil
    end

    def stamp_updated_by
      self.updated_by = self.class.current.present? ? self.class.current.id : nil
    end
  end
end
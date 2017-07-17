ActiveRecord::Base.send(:include, ActiveModel::ForbiddenAttributesProtection)

module ClosureTree
  class Support
    def use_attr_accessible?
      false
    end
  end
end
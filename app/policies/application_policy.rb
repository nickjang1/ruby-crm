class ApplicationPolicy
  def initialize(user, record)
    raise Pundit::NotAuthorizedError 'must be logged in' unless user
    @user = user
    @record = record
    subject = if record.is_a? Class
                record.model_name.singular.to_sym
              else
                record.class.model_name.singular.to_sym
              end
    @permissions = user.permitted_permissions(subject)
    @permission_attributes = @permissions.map(&:permission_attribute)
  end

  def edit?
    false
  end

  def update?
    edit?
  end
end

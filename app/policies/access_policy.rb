class AccessPolicy < Struct.new(:user, :access)

  def initialize(user, access)
    @user = user
    @permitted_actions = user.permitted_permissions(:access).map(&:permission_attribute).map(&:action).map(&:to_sym).uniq
  end

  PermissionAttribute.access_attributes.pluck(:action).each do |action|
    define_method("#{action}?") { @permitted_actions.include?(action.to_sym) }
  end

  def maintenance?
    @permitted_actions.include?(:maintenance) || @user.corporate?
  end

  def work_order?
    @permitted_actions.include?(:work_order) || @user.corporate?
  end

  def connect_corporate?
    @user.current_property_role.gm? || @user.current_property_role.admin? || @permitted_actions.include?(:connect_corporate)
  end

  def permission_setting?
    @user.current_property_role.gm? || @user.current_property_role.admin? || @permitted_actions.include?(:permission_setting)
  end

  def settings?
    @user.current_property_role && (@user.current_property_role.gm? || @user.current_property_role.admin? || @permitted_actions.include?(:settings))
  end

end

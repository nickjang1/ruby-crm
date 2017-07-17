class Maintenance::WorkOrderPolicy < Maintenance::BasePolicy
  class Scope < Scope
    def index_departments
      index_scopes.select_in_hash(:department).map { |option| option[:departments] }.flatten.uniq
    end

    def resolve
      if index_scopes.include_in_hash?(:all)
        @scope.all
      else
        sql = nil
        if index_scopes.include_in_hash?(:own) && index_scopes.include_in_hash?(:assigned_to)
          # @scope.where("opened_by_user_id = ? OR assigned_to_id = ?", @user.id, @user.id)
          sql = "opened_by_user_id = #{@user.id} OR assigned_to_id = #{@user.id}"
        elsif index_scopes.include_in_hash? :own
          # @scope.where(opened_by_user_id: @user.id)
          sql = "opened_by_user_id = #{@user.id}"
        elsif index_scopes.include_in_hash? :assigned_to
          # @scope.where(assigned_to_id: @user.id)
          sql = "assigned_to_id = #{@user.id}"
        else
          # @scope.none
        end
        if index_scopes.include_in_hash?(:department) && index_departments.count > 0
          @scope = @scope.by_departments(index_departments, sql)
        else
          sql.nil? ? @scope.none : @scope.where(sql)
        end
      end
    end
  end

  def index?
    @user.corporate? || (@permissions.by_attribute_action(:index).pluck(:options).flatten.compact.uniq.count > 0)
  end

  %w(edit edit_closed destroy).each do |action|
    define_method("#{action}?") { @permission_attributes.map(&:action).include?(action) }
  end

  def create?
    (@user.corporate? && @user.all_properties.count > 0) || @permission_attributes.map(&:action).include?('create')
  end

  def base_attributes
    [
      :description, :maintainable_id, :maintainable_type, :other_maintainable_location, :closing_comment, :duration,
      :attachments_attributes => [:id, :file, :_destroy ],
      :checklist_item_maintenance_attributes => [:id, :maintenance_checklist_item_id, :_destroy ]
    ]
  end

  def primary_attributes
    [:status, :priority, :assigned_to_id, :due_to_date]
  end
end

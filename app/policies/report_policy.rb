class ReportPolicy < ApplicationPolicy

  def index?
    return true if @user.corporate
    @permission_attributes.map(&:action).include? 'index'
  end

end

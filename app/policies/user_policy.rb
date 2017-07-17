class UserPolicy < ApplicationPolicy

  %w(index new create destroy).each do |action|
    define_method("#{action}?") { has_team_permission? }
  end

  %w(edit change_password update).each do |action|
    define_method("#{action}?") { has_team_permission? || @record == @user }
  end

  private

  def has_team_permission?
    @permission_attributes.map(&:action).include?('index') || @user.corporate?
  end

end

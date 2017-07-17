class Maintenance::BasePolicy < ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
      subject = scope.model_name.singular.to_sym
      @permissions ||= user.permitted_permissions subject
    end

    def index_scopes
      # flatten permissions since there are several permissions related to department
      @scopes ||= @permissions.by_attribute_action(:index).pluck(:options).flatten.uniq
    end

    def option_include?(options, option)
      options.any? { |o| o.is_a?(Hash) ? o[:option] == option : o == option }
    end
  end

  def base_attributes
    []
  end

  def permitted_attributes
    if @record.nil?
      full_attributes
    else
      base_attributes + @permissions.by_attribute_action(:edit).pluck(:options).flatten.uniq
    end
  end

  def full_attributes
    base_attributes + primary_attributes
  end
end

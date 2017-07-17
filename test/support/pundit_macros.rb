def permit!(current_context, record, action)
  assert Pundit.authorize(current_context, record, action)
rescue Pundit::NotAuthorizedError
  false
end

def forbid!(current_context, record, action)
  assert !Pundit.authorize(current_context, record, action)
rescue Pundit::NotAuthorizedError
  false
end

def permit_attributes!(current_context, record, attributes)
  assert (attributes - Pundit.policy!(current_context, record).permitted_attributes).empty?
end

def forbid_attributes!(current_context, record, attributes)
  assert !(attributes - Pundit.policy!(current_context, record).permitted_attributes).empty?
end

def permit_scope!(current_context, scope, records)
  ids = records.map(&:id)
  assert (ids - Pundit.policy_scope!(current_context, scope).pluck(:id)).empty?
end

def forbid_scope!(current_context, scope, records)
  ids = records.map(&:id)
  assert !(ids - Pundit.policy_scope!(current_context, scope).pluck(:id)).empty?
end

def attribute(name)
  PermissionAttribute.find_by name: name
end

def check_permission(record, action, name)
  gm = create(:user, current_property_role: Role.gm)
  agm = create(:user, current_property_role: Role.agm)
  department = create(:department)
  gm.departments << department
  gm.save

  forbid!(gm, record, action)

  create(:permission, department: department, role: Role.gm, permission_attribute: attribute(name))
  permit!(gm, record, action)

  gm.departments.destroy_all
  gm.departments << create(:department)
  gm.save
  forbid!(gm, record, action)

  forbid!(agm, record, action)
  agm.departments << department
  agm.save
  forbid!(agm, record, action)

  create(:permission, department: department, role: Role.agm, permission_attribute: attribute(name))
  permit!(agm, record, action)
end
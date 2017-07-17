require 'test_helper'

describe 'Departments Integration' do
  before do
    user = create(:user, current_property_role: Role.gm)
    create(:permission, role: Role.gm, department: user.departments.first, permission_attribute: attribute('Team'))
    sign_in user
  end

  it "creating new department and checking it's edit page after that", js: true do
    categories = create_list(:category, 3)
    users = create_list(:user, 4)
    
    # creating some users for other property:
    current_property_id = Property.current_id
    Property.current_id = create(:property).id
    create_list(:user, 2)
    Property.current_id = current_property_id

    visit new_department_path
    fill_in('Department name', with: 'Dep 1')

    # save_and_open_page
    assert page.has_css?('table.test-department-category tbody tr', count: 3)
    assert page.has_css?('table.test-department-user tbody tr', count: 5)

    # adding couple of categories:
    assert page.has_css?('table.test-department-category tbody tr.success', count: 0)
    find(".test-add-category-#{categories[0].id}").trigger('click')
    assert !page.has_css?(".test-add-category-#{categories[0].id}")
    assert page.has_css?(".test-remove-category-#{categories[0].id}")
    
    find(".test-add-category-#{categories[1].id}").trigger('click')
    assert !page.has_css?(".test-add-category-#{categories[1].id}")
    
    assert page.has_css?('table.test-department-category tbody tr.success', count: 2)

    # adding couple of users:
    assert page.has_css?('table.test-department-user tbody tr.success', count: 0)
    find(".test-add-user-#{users[0].id}").trigger('click')
    assert !page.has_css?(".test-add-user-#{users[0].id}")
    assert page.has_css?(".test-remove-user-#{users[0].id}")

    find(".test-add-user-#{users[1].id}").trigger('click')
    find(".test-add-user-#{users[2].id}").trigger('click')
    assert page.has_css?('table.test-department-user tbody tr.success', count: 3)

    click_button 'Create Department'

    flash_messages[0].must_include "Department Dep 1 was successfully updated"
    
    # screenshot_and_open_image
    click_link 'Dep 1'

    assert page.has_css?('table.test-department-category tbody tr.success', count: 2)
    assert page.has_css?('table.test-department-user tbody tr.success', count: 3)
    
    # removing one category:
    find(".test-remove-category-#{categories[0].id}").trigger('click')
    assert page.has_css?('table.test-department-category tbody tr.success', count: 1)

    # removing one user:
    find(".test-remove-user-#{users[0].id}").trigger('click')
    assert page.has_css?('table.test-department-user tbody tr.success', count: 2)
    click_button 'Update Department'

    page.has_css?('.breadcrub li', 'Departments')
    flash_messages[0].must_include "Department Dep 1 was successfully updated"

    click_link 'Dep 1'

    assert page.has_css?('table.test-department-category tbody tr.success', count: 1)
    assert page.has_css?('table.test-department-user tbody tr.success', count: 2)
  end
end
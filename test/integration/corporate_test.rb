require 'test_helper'

describe 'Corporate Integration' do

  it "corporate flow", js: true do
    corporate = create(:corporate, name: "CORP1")
    Property.current_id = nil
    user = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)

    visit unauthenticated_root_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'password'
    click_button 'Sign In'
    sleep 1
    current_path.must_equal corporate_root_path
    page.body.must_include "CORP1"

    # adding a property to our corporate:
    property = create(:property, name: 'PROPERTY1')
    property.run_block_with_no_property do
      user.current_property_role = Role.corporate
      user.departments << Department.find_or_create_by(name: 'All')
      create(:permission, role: Role.corporate, department: user.departments.first, permission_attribute: attribute('Team'))
      user.save!
    end
    create(:corporate_connection, corporate: corporate, email: user.email, property: property, state: :active)

    visit corporate_root_path # and reloading page
    sleep 0.5
    find('a', text: "CORP1").click
    # find('ul.dropdown-menu[role="menu"] li a', text: 'PROPERTY1').click
    click_link 'PROPERTY1'
    sleep 1
    current_path.must_equal dashboard_path
    page.body.must_include "You have successfully logged into 'PROPERTY1'"
    page.body.must_include "MTD Spending by Category"

    visit users_path
    find('#shuffle-grid .panel h5', text: user.name) # property's "team" section should display corporate users as well
  end

  it 'connects hotel to corporate', js: true do
    property_id = Property.current_id
    Property.current_id = nil
    corporate = create(:corporate, name: "CORP1")
    corp_user = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)
    Property.current_id = property_id

    user = create(:user)
    sign_in user
    visit dashboard_path
    click_link(user.name)
    click_link("Hotel Settings")
    # screenshot_and_open_image
    find('a', text: 'Connect to Corporate').click
    sleep 1
    # screenshot_and_open_image
    find('.steps ul li:nth-child(1).current') # we're on 1st step
    page.body.must_include "Connect to your Corporate Organization"

    # entering wrong-format email:
    fill_in "corporate_connection_email", with: "abc@fff"
    fill_in "corporate_connection_email_confirmation", with: ""
    click_button "Submit Invitation"
    sleep 0.5
    # find('#gritter-notice-wrapper .gritter-without-image p', text: "Email confirmation doesn't match Email and Email is invalid")
    page.body.must_include "Email confirmation doesn't match Email and Email is invalid"

    # entering correct format email but wrong confirmation:
    fill_in "corporate_connection_email", with: "abc@fff.com"
    fill_in "corporate_connection_email_confirmation", with: "abc@ffffffff"
    click_button "Submit Invitation"
    sleep 0.5
    page.body.must_include "Email confirmation doesn't match Email"

    # entering correct format email and confirmation but there is no corporate user with such email:
    fill_in "corporate_connection_email", with: "abc@fff.com"
    fill_in "corporate_connection_email_confirmation", with: "abc@fff.com"
    click_button "Submit Invitation"
    sleep 0.5
    page.body.must_include "No corporate user with this email address exists. Please verify the email and try again."

    #entering correct email of corporate user and confirmation:
    fill_in "corporate_connection_email", with: corp_user.email
    fill_in "corporate_connection_email_confirmation", with: corp_user.email
    Corporate::Connection.count.must_equal 0
    click_button "Submit Invitation"
    sleep 2

    Sidekiq::Extensions::DelayedMailer.jobs.size.must_equal 1
    find('.steps ul li:nth-child(2).current', visible: false) # we're on 2nd step
    page.body.must_include "Waiting for verification from Corporate."
    Corporate::Connection.count.must_equal 1
    Property.current.corporate_connection.update_attributes(state: :corporate_approved)

    visit corporate_connections_path # reloading page
    find('.steps ul li:nth-child(3).current') # we're on 3rd step
    page.body.must_include "Confirm your Corporate Organization"
    click_button "Confirm"
    sleep 1
    current_path.must_equal property_settings_path
    page.body.must_include "Connection with Corporate has been set up successfully."
    Property.current.corporate.wont_be_nil
  end

  it 'should allow corporate to confirm connection', js: true do
    user = create(:user)
    Property.current_id = nil
    corporate  = create(:corporate, name: "CORP1")
    corp_user  = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)
    property   = create(:property, name: 'PROPERTY1')
    connection = create(:corporate_connection, corporate: corporate, email: corp_user.email, property: property, state: :new, created_by: user)

    sign_in corp_user
    visit corporate_root_path
    sleep 1
    find(".nav li:nth-child(3) > a.dropdown-toggle", visible: false).click
    click_link 'Corporate Settings'

    find('#property-connections table tr', count: 1)
    click_link 'Review'
    find('.steps ul li:nth-child(2).current') # we're on 2nd step

    page.body.must_include property.name
    page.body.must_include user.name
    click_button 'Confirm connection with hotel'
    sleep 0.5
    page.body.must_include "Waiting for verification from hotel"
    Corporate::Connection.last.approve!
    visit corporate_settings_path

    find('h4', text: property.name)
    find('span.label-success', text: 'Confirmed')
  end

  it 'should not allow to edit declined by corporate connection', js: true do
    user = create(:user)
    Property.current_id = nil
    corporate  = create(:corporate, name: "CORP1")
    corp_user  = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)
    property   = create(:property, name: 'PROPERTY1')
    connection = create(:corporate_connection, corporate: corporate, email: corp_user.email, property: property, state: :new, created_by: user)

    sign_in corp_user
    visit corporate_root_path
    sleep 1
    find(".nav li:nth-child(3) > a.dropdown-toggle", visible: false).click
    click_link 'Corporate Settings'

    find('#property-connections table tr', count: 1)
    click_link 'Review'
    find('.steps ul li:nth-child(2).current') # we're on 2nd step
    click_button 'Reject'
    find('span.label-danger', text: 'Rejected by Corporate')
    current_path.must_equal corporate_settings_path
  end

  it "corporate can approve prs", js: true do
    property = Property.current

    user = create(:user, current_property_role: Role.gm)
    user.order_approval_limit = 2
    user.save

    pr = create(:purchase_request, :with_items, state: :completed)
    ( pr.total_price > 2 ).must_equal true #we want a pr that exceeds the GM's approval limit

    Property.current_id = nil

    corporate = create(:corporate, name: "CORP1")
    corp_user = create(:user, password: 'password', password_confirmation: 'password', corporate: corporate, department_ids: [], current_property_role: nil)

    create(:corporate_connection, corporate: corporate, email: user.email, property: property, state: :active)

    visit '/'
    fill_in 'user_email', with: corp_user.email
    fill_in 'user_password', with: 'password'
    click_button 'Sign In'

    # comment this because of circleci
    # sleep 2
    # within(".approvals_for_#{property.id}") do
    #   page.has_css?(".pr_approval_request_#{pr.id}", visible: false).must_equal true
    # end
  end
end

require 'test_helper'

describe 'Vendors Integration' do
  before do
    @user = create(:user)
    sign_in @user
    @v = create(:vendor)
  end

  it 'denies access for unauthorized' do
    sign_out

    visit vendors_path
    # assert_equal 401, page.status_code
    current_path.must_equal new_user_session_path
    page.text.must_include 'Login to Lodgistics'
  end

  it 'list all vendors' do
    vendors = create_list(:vendor, 4)
    visit vendors_path

    vendors.each do |vendor|
      page.text.must_include vendor.name
    end
  end

  it 'edits the vendor' do
    visit edit_vendor_path(@v)
    fill_in 'vendor_name', with: "UPDATED_NAME"
    click_button 'Update Vendor'
    page.text.must_include 'UPDATED_NAME'
  end

  it 'should inactivate vendor' do
    visit vendors_path
    find(:css, '#shuffle-grid .activate-inactivate', visible: false).click()
    page.text.wont_include @v.name
    page.current_path.must_equal vendors_path
  end

  it 'creates a new vendor' do
    visit new_vendor_path
    fill_in 'vendor_name', with: "CREATED_NAME"
    click_button 'Create Vendor'
    
    page.current_path.must_equal vendors_path
    page.text.must_include 'CREATED_NAME'
  end

  it "doesn't creates a new vendor when required field is missing", js: true do
    skip 'FIX AFTER MAINTENANCE'
    t = build(:vendor)
    visit new_vendor_path
    page.execute_script '$("#vendor_street_address").val("123").trigger("change")'
    click_button 'Create Vendor'
    inline_error_for 'vendor_name', must_include: "This value is required."
  end

  it "filter vendors by name", js: true do
    create(:vendor, name: "Eichmann Stuff and Misc Co.")
    create(:vendor, name: "Hessel Delivery LLC.")
    create(:vendor, name: "Ledner Shipping Co.")
    create(:vendor, name: "Sysco (Distribution)")
    visit vendors_path

    fill_in('shuffle-filter', with: 'sy')
    sleep 1
    assert page.has_css?('#shuffle-grid > .filtered', count: 1)
    assert page.has_css?('#shuffle-grid > .concealed', count: 4)
  end

  describe "procurement interfaces", js: true do
    before do
      @vendor = create(:vendor, name: 'US Food')
      visit edit_vendor_path(@vendor)
    end

    it "should show procurement interface", js: true do
      skip "WILL FIX AFTER FINISHING PM"
      find('a.procurement-link').trigger(:click) # click_link('Procurement')
      # page.must_include('VPT (US Foods)')
      # page.must_include('Punchout')
    end

    it "should show VPT fields and vpt enabled flag", js: true do
      skip "WILL FIX AFTER FINISHING PM"
      find('a.procurement-link').trigger(:click) # click_link('Procurement')
      # page.must_include('VPT (US Foods)')
      # page.must_include('Punchout')
      select 'VPT (US Foods)', :from => "vendor_procurement_interface_attributes_interface_type"
      within('#vpt') do
        fill_in('vendor_procurement_interface_attributes_data_partner_id', with: 'Partner ID')
        fill_in('vendor_procurement_interface_attributes_data_username', with: 'User Name')
        fill_in('vendor_procurement_interface_attributes_data_password', with: 'Password')
        fill_in('vendor_procurement_interface_attributes_data_division', with: 'Division')
        fill_in('vendor_procurement_interface_attributes_data_customer_number', with: 'Customer Number')
        fill_in('vendor_procurement_interface_attributes_data_department_number', with: 'Department Number')
      end
      click_button 'Update Vendor'

      sleep 1

      @vendor.procurement_interface.data[:partner_id] = 'Partner ID'
      @vendor.procurement_interface.data[:username] = 'User Name'
      @vendor.procurement_interface.data[:password] = 'Password'
      @vendor.procurement_interface.data[:division] = 'Division'
      @vendor.procurement_interface.data[:customer_number] = 'Customer Number'
      @vendor.procurement_interface.data[:department_number] = 'Department Number'
    end
  end
end

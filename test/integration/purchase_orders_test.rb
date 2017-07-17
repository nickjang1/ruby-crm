require 'test_helper'

def send_fax
  visit purchase_order_path({id: @po.id})
  find("div.page-header button.dropdown-toggle[data-toggle=\"dropdown\"]").trigger(:click)
  find("a.send-fax-link").trigger(:click)
  find("a", text: 'YES I\'m sure!').trigger(:click)
  sleep(0.5)
end

describe 'Purchase Orders Integration' do
  before do
    @user = create(:user)
    sign_in @user
    @item = create(:item)
    @vendor = create(:vendor)
    @vendor.vendor_items << create(:vendor_item, item: @item)
    @po = create(:purchase_order, vendor: @vendor, state: 'open')
    @po.item_orders << create(:item_order, item: @item)
    @vpt_interface_values = {interface_type: :vpt, data: {partner_id: '1', username: 'username', password: 'password'}}
  end

  it 'shows all orders' do
    @po1 = create(:purchase_order, vendor: @vendor, state: 'open')
    @po1.item_orders << create(:item_order, item: @item)
    @po1.sent!

    visit purchase_orders_path
    all('table.column-filtering tbody tr').count.must_equal 2
    find("td", text: @po.number)
    find("td", text: @po1.number)
    find('.badge.badge-primary', text: 'Open')
    find('.badge.badge-success', text: 'Sent')
  end

  it 'changes order state to sent', js: true do
    visit purchase_orders_path
    find(".btn.btn-danger.dropdown-toggle").trigger(:click)
    find("li a.has-tip[title=\"Mark as Sent\"]").trigger(:click)
    sleep(1)
    @po.reload
    @po.state.must_equal 'sent'
  end

  it 'shows all items in order detail page' do
    visit purchase_order_path(@po)
    all('table.column-filtering tbody tr').count.must_equal 1
    find('h3.semibold.text-success', text: '$200.0')
  end


  it 'shows danger notification if vendor doesn\'t have fax number', js: true do
    visit purchase_order_path({id: @po.id})
    find("div.page-header button.dropdown-toggle[data-toggle=\"dropdown\"]").trigger(:click)
    assert !page.has_content?("a.send-fax-link")
  end

  it 'sends fax', js: true do
    @po.vendor.fax = '+19193770445'
    @po.vendor.save!
    @po.vendor
    send_fax
    find_notification 'success', 'Fax is being processing.'
    assert_equal 1, FaxWorker.jobs.size
    FaxWorker.drain
    assert_equal 0, FaxWorker.jobs.size
    @po.update(fax_id: 'test_fax')

    post '/phaxio', {fax: "{\"id\":\"#{@po.fax_id}\",\"status\":\"success\"}"}
    @po.reload
    @po.state.must_equal 'sent'
  end

  it 'should show VPT action', js: true do
    @po.vendor.update_attributes(procurement_interface_attributes: @vpt_interface_values)
    visit purchase_order_path(@po)
  end
  
  it 'succeeds to add message', js: true do
    skip "WILL FIX AFTER FINISHING PM"
    @po.sent!
    visit purchase_order_path(@po)
    assert !page.has_css?('span.message-count.text-danger')
    find('.test-messages-chat-icon').trigger(:click)
    assert page.has_css?('span.count', text: '(0)')
  
    # open new message dialog
    find_link_with_icon('btn-info', 'ico-pencil', 'Add Comment').trigger(:click)
    assert page.has_css?('.new-message-modal').must_equal true
    assert page.has_css?('.new-message-modal h4.modal-title', text: "Add Comment to Order #{@po.number}").must_equal true
    click_button 'Save Comment'
  
    # validation
    find('.new-message-modal #message-body')['class'].must_include 'parsley-error'
  
    # add message
    fill_in 'message-body', with: 'message added on order show page'
    click_button 'Save Comment'
    
    # check icon, message count, stylesheet
    assert page.has_css?('#messages-icon.text-primary').must_equal true
    find('.test-messages-chat-icon').trigger(:click)
    assert page.has_css?('span.count', text: '(1)').must_equal true
    assert page.has_css?('span.media-heading', text: @user.name)
    assert page.has_css?('span.media-text', text: 'message added on order show page')
      
    # request page
    find_link_with_icon('btn-inverse', 'ico-truck', 'Receive').trigger(:click)
    page.has_content?("Receive Purchase Order #{@po.number}")

    # check icon, message count, stylesheet
    assert page.has_css?('#messages-icon.text-primary').must_equal true
    find('.test-messages-chat-icon').trigger(:click)
    assert page.has_css?('span.count', text: '(1)').must_equal true
    assert page.has_css?('span.media-heading', text: @user.name)
    assert page.has_css?('span.media-text', text: 'message added on order show page')
    
    # add message on receive page
    find('a#new-message').trigger(:click)
    assert page.has_css?('.new-message-modal').must_equal true
    assert page.has_css?('.new-message-modal h4.modal-title', text: "Add Comment to Order #{@po.number}").must_equal true
    fill_in 'message-body', with: 'message added on receive page'
    click_button 'Save Comment'
    page.has_content?("Receive Purchase Order #{@po.number}")
    
    find_button_with_icon('btn-primary', 'ico-truck', 'Receive').trigger(:click)

    # check message added on receive page
    visit purchase_order_path(@po)
    assert !page.has_css?('span.message-count.text-danger')
    find('.test-messages-chat-icon').trigger(:click)
    assert page.has_css?('span.count', text: '(2)')
    assert page.has_css?('#messages-icon.text-primary').must_equal true
    assert page.has_css?('span.media-heading', text: @user.name)
    assert page.has_css?('span.media-text', text: 'message added on order show page')
    assert page.has_css?('span.media-text', text: 'message added on receive page')
  end

end

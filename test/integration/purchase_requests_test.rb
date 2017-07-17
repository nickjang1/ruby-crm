require 'test_helper'

describe 'Purchase Requests Integration' do
  include UsesTempFiles
      
  before(:each) do
    @user = create(:user)
    @approver = create(:user, current_property_role: Role.gm)
    sign_in @user

    @pr = create(:purchase_request)
  end

  it 'must create a new request after going through the wizard', js: true do
    @user.current_property_user_role.update(order_approval_limit: 1000000)
    list = create(:list)
    visit new_purchase_request_path(q: {lists_id_eq_any: [list.id]})
    complete_pr_wiz

    page.has_content?("Request #{PurchaseRequest.last.number} approved and 1 Orders created.").must_equal true
  end
  
  it 'shows old requests are ordered already', js: true do
    @user.current_property_user_role.update(order_approval_limit: 1000000)
    list = create(:list)
    visit new_purchase_request_path(q: {lists_id_eq_any: [list.id]})
    complete_pr_wiz
    page.has_content?("Request #{PurchaseRequest.last.number} approved and 1 Orders created.").must_equal true
    
    ordered_pr = PurchaseRequest.last
    
    click_link 'Active'
    page.has_content?(@pr.number)
    page.has_content?(ordered_pr.number).must_equal false
    click_link 'Closed'
    page.has_content?(ordered_pr.number)
    page.has_content?(@pr.number).must_equal false
    page.has_content?('1 PO')
  end
  
  describe 'messages feature' do
    ATTACHMENT_TEMP_FILE = 'attachment.txt'
    in_directory_with_file(ATTACHMENT_TEMP_FILE)
  
    it 'must show chat icon on inventory, request, approve pages', js: true do
      list = create(:list)
      visit new_purchase_request_path(q: {lists_id_eq_any: [list.id]})
      # assert page.has_css?('span.meta#messages-icon')
      find_link_with_icon('btn-primary', 'ico-next', 'Next').trigger(:click)
      assert page.has_css?('span.meta#messages-icon')
      fill_in 'purchase_request_item_requests_attributes_0_quantity', with: "5"
      find_link_with_icon('btn-primary', 'ico-next', 'Next').trigger(:click)
      assert page.has_css?('span.meta#messages-icon')
    end
    
    describe 'adds message on inventory page and displays it' do
      before do
        content_for_file('this is test file')
      end
      
      it 'should success', js: true do
        skip "WILL FIX AFTER FINISHING PM"
        list = create(:list)
        visit new_purchase_request_path(q: {lists_id_eq_any: [list.id]})
        page.has_content?('Inventory').must_equal true
        assert !page.has_css?('span#messages-alert-icon')
        find('.test-messages-chat-icon').trigger(:click)
        assert page.has_css?('span.count', text: '(0)')
      
        # open new message dialog
        find('a#new-message').trigger(:click)
        assert page.has_css?('.new-message-modal').must_equal true
        assert page.has_css?('.new-message-modal h4.modal-title', text: "Add Comment to Request").must_equal true
        click_button 'Save Comment'
      
        # validation
        find('.new-message-modal #message-body')['class'].must_include 'parsley-error'
      
        # add message
        fill_in 'message-body', with: 'test message'
        attach_file 'message-attachment', File.expand_path(File.open(ATTACHMENT_TEMP_FILE))
        click_button 'Save Comment'
        
        # check icon, message count, stylesheet
        assert page.has_css?('#messages-icon.text-primary').must_equal true
        find('.test-messages-chat-icon').trigger(:click)
        assert page.has_css?('span.count', text: '(1)').must_equal true
        assert page.has_css?('span.media-heading', text: @user.name)
        assert page.has_css?('span.media-text', text: 'test message')
        assert page.has_css?('span#messages-alert-icon')
        assert page.has_css?('span.label.label-success', text: 'txt')
        page.has_content?('attachment.txt').must_equal true
      
        # request page
        find_link_with_icon('btn-primary', 'ico-next', 'Next').trigger(:click)
        page.has_content?("Request #{PurchaseRequest.last.number}")

        # check icon, message count, stylesheet
        assert page.has_css?('#messages-icon.text-primary').must_equal true
        find('.test-messages-chat-icon').trigger(:click)
        assert page.has_css?('span.count', text: '(1)').must_equal true
        assert page.has_css?('span.media-heading', text: @user.name)
        assert page.has_css?('span.media-text', text: 'test message')
        assert page.has_css?('span.label.label-success', text: 'txt')
        page.has_content?('attachment.txt').must_equal true

        # approve page
        fill_in 'purchase_request_item_requests_attributes_0_quantity', with: "5"
        find_link_with_icon('btn-primary', 'ico-next', 'Next').trigger(:click)
        page.has_content?("Request Approval #{PurchaseRequest.last.number}").must_equal true

        # check icon, message count, stylesheet
        assert page.has_css?('#messages-icon.text-primary').must_equal true
        find('.test-messages-chat-icon').trigger(:click)
        assert page.has_css?('span.count', text: '(1)').must_equal true
        assert page.has_css?('span.media-heading', text: @user.name)
        assert page.has_css?('span.media-text', text: 'test message')
        assert page.has_css?('span.label.label-success', text: 'txt')
        page.has_content?('attachment.txt').must_equal true
      end
    end
  end

  it 'must create a background job for sending approval', js: true do
    skip "WILL FIX AFTER FINISHING PM"
    @approver.current_property_user_role.update(order_approval_limit: 1000000)
    list = create(:list)
    visit new_purchase_request_path(q: {lists_id_eq_any: [list.id]})
    find(".test-next-btn").trigger('click')

    fill_in 'purchase_request_item_requests_attributes_0_quantity', with: "5"
    find(".test-next-btn").trigger('click')

    sleep(0.5)

    assert_equal 1, RequestApprovalWorker.jobs.size
    RequestApprovalWorker.drain
    assert_equal 0, RequestApprovalWorker.jobs.size
    assert_equal 1, mail_count
    Notification.last.user_id.must_equal @approver.id
    find_notification 'success', "Request (#{PurchaseRequest.last.number}) approval is sent to GM(s)."

    sign_in @approver
    visit edit_purchase_request_path(PurchaseRequest.last)
    find(".test-approve-btn").trigger(:click)
    find('a', text: 'YES').trigger(:click)
    sleep(0.5)
    flash_messages.first.must_include "Request #{PurchaseRequest.last.number} approved and 1 Orders created."
  end


  it 'must create a request from category' do
    cat = create(:category)
    items = create_list(:item, 5, categories: [cat])
    visit categories_path
    find(:xpath, '//div[contains(@class, "widget")]//a[contains(text(), "Order")]').click
    items.each do |item|
      page.text.must_include item.name
    end
  end

  it 'must create a request from location' do
    location = create(:location)
    items = create_list(:item, 5, locations: [location])
    visit locations_path
    find(:xpath, '//div[contains(@class, "widget")]//a[contains(text(), "Order")]').click
    items.each do |item|
      page.text.must_include item.name
    end
  end

  it 'must create a request from item listing' do
    items = create_list(:item, 5)
    visit new_purchase_request_path(q: {id_in: items.map(&:id)})
    items.each do |item|
      page.text.must_include item.name
    end
  end

  it 'must generate item requests based on a list id' do
    list = create(:list)
    items = create_list(:item, 5)
    list.items << items
    visit new_purchase_request_path(q: {lists_id_eq_any: [list.id]})
    items.each do |item|
      page.text.must_include item.name
    end
  end

  it 'must create PR from selected items', js: true do
    potential_approver = create(:user, current_property_role: Role.gm)
    potential_approver.current_property_user_role.update(order_approval_limit: 1000000)

    @user.current_property_user_role.update(order_approval_limit: 1000000)
    items = create_list(:item_with_vendor_item, 5)
    visit items_path
    find(:css, "label[for='customcheckbox-item-#{ items[0].id }']").click
    find(:css, "label[for='customcheckbox-item-#{ items[1].id }']").click
    find(:css, "label[for='customcheckbox-item-#{ items[2].id }']").click
    find(:css, "label[for='customcheckbox-item-#{ items[3].id }']").click
    click_link 'order_selected_items'

    #<==== INVENTORY STEP:
    assert page.has_css?('table tbody tr', count: 4)

    find('table tbody tr:nth-child(1) td.skip-inv-cell .badge')
    find('table tbody tr:nth-child(2) td.skip-inv-cell .badge')
    find('table tbody tr:nth-child(3) td.skip-inv-cell .badge')
    find('table tbody tr:nth-child(4) td.skip-inv-cell .badge')

    # should not allow to input non-digits:
    fill_in('purchase_request_item_requests_attributes_0_count', with: 'asdsfd')
    find('table tbody tr:nth-child(1) td.skip-inv-cell .badge')
    # should allow to input digits:
    fill_in('purchase_request_item_requests_attributes_0_count', with: '12.5')
    assert page.has_no_css?('table tbody tr:nth-child(1) td.skip-inv-cell .badge')

    find(".test-next-btn").trigger(:click)
    #<==== REQUEST STEP:
    sleep 2
    # save_and_open_page
    page.text.must_include "12.5" # on-hand quantity we have entered on previous step
    assert page.has_css?('table tbody tr', count: 4)
    find('table thead th:nth-child(4)').trigger(:click) # sorting by QTY

    assert page.has_css?('.badge-danger', text: 'Skipped', count: 3) # should be 3 skipped items
    find_field('purchase_request_item_requests_attributes_0_quantity').value.must_equal '0'
    find_field('purchase_request_item_requests_attributes_1_quantity').value.must_equal '0'
    find_field('purchase_request_item_requests_attributes_2_quantity').value.must_equal '0'
    find_field('purchase_request_item_requests_attributes_3_quantity').value.must_equal '0'

    find('table tbody tr:nth-child(1) .item-total-price .value', text: '0.00')
    find('table tbody tr:nth-child(2) .item-total-price .value', text: '0.00')
    find('table tbody tr:nth-child(3) .item-total-price .value', text: '0.00')
    find('table tbody tr:nth-child(4) .item-total-price .value', text: '0.00')

    # should not allow to input non-digits:
    # screenshot_and_open_image
    find('table tbody tr:nth-child(1) td:nth-child(5) input[type="number"]').set("fdfkdf")
    find('table tbody tr:nth-child(1) .item-total-price .value', text: '0.00') # total should not change
    find('.total-price-value', text: '0.00') # grand total should not change

    # should allow to input digits:
    find('table tbody tr:nth-child(1) td:nth-child(5) input[type="number"]').set("1.5")
    # all items have price of $200
    
    find('table tbody tr:nth-child(1) .item-total-price .value', text: '300.00') # total should change
    find('.total-price-value', text: '300.00') # grand total also should change

    find('table tbody tr:nth-child(2) td:nth-child(5) input[type="number"]').set("2")
    find('table tbody tr:nth-child(2) .item-total-price .value', text: '400.00') # total should change
    find('.total-price-value', text: '700.00')

    find(".test-next-btn").trigger(:click)
    #<==== APPROVE STEP:
    sleep 1

    assert_equal 1, RequestApprovalWorker.jobs.size
    RequestApprovalWorker.drain
    assert_equal 0, RequestApprovalWorker.jobs.size

    # screenshot_and_open_image
    assert page.has_css?('table tbody tr', count: 2)
    page.text.must_include "12.5"
    page.text.must_include "$400.00"
    page.text.must_include "$300.00"
    page.text.must_include "$700.00"


    find(".test-approve-btn").trigger(:click)
    find('a', text: 'YES').trigger(:click)
    sleep(0.5) #I have no idea

    assert RequestCheckWorker.jobs.any?
    RequestCheckWorker.drain
    assert_equal 0, RequestCheckWorker.jobs.size

    flash_messages.first.must_include "Request #{PurchaseRequest.last.number} approved and 2 Orders created."
  end

  it 'should request for message when rejecting request', js: true do
    @user.current_property_user_role.update_attributes order_approval_limit: 5000
    pr = create(:purchase_request, :with_items)
    visit edit_purchase_request_path(pr)
    find(".test-next-btn").click
    sleep 0.5
    fill_in 'purchase_request_item_requests_attributes_0_quantity', with: "5"
    find(".test-next-btn").click
    find(:xpath, "//a[text()=' Reject']").click
    within('.modal-dialog') do
      page.has_css?("button#confirm-rejection").must_equal true
      find("#confirm-rejection")['disabled'].wont_be_nil
      fill_in 'rejection-reason', with: 'some good reason'
      find("#confirm-rejection")['disabled'].must_be_nil
      find("#confirm-rejection").click
    end

    # click_link ".test-pr-#{pr.id}"
    # page.has_content?('some good reason').must_equal true
  end

  protected

  def click_submit
    # Can't use normal link click here because some javascript
    # bullshit enables the link after page load.
    page.find("a[data-action='submit']").click
  end

  def complete_pr_wiz
    find(".test-next-btn").click

    fill_in 'purchase_request_item_requests_attributes_0_quantity', with: "5"
    find(".test-next-btn").click
    find(".test-approve-btn").trigger('click')

    find('a', text: 'YES').click
    sleep(0.5) #I have no idea
  end
end

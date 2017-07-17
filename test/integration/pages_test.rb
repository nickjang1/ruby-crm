require 'test_helper'

describe 'Pages Integration' do
  before do
    @user = create(:user)
    sign_in @user
  end

  describe 'Dashboard Integration' do    
    describe 'lists' do
      let(:invisible_list) { create(:list) }
      let(:visible_lists) { create_list(:list, 6) }

      before do
        visible_lists.each do |list|
          UserListUsage.create(list_id: list.id, user_id: @user.id)
        end
      end

      it 'must display the top 6 most frequently ordered lists' do
        visit dashboard_path
        
        within('#lists') do
          visible_lists.each do |list|
            page.text.must_include list.name
          end
          
          page.text.wont_include invisible_list.name
        end
      end
        
      it 'must display the lists in the correct order' do
        list1 = visible_lists.first
        UserListUsage.create(list_id: list1.id, user_id: @user.id)
      
        list2 = visible_lists.last
        UserListUsage.create(list_id: list2.id, user_id: @user.id)
        UserListUsage.create(list_id: list2.id, user_id: @user.id)
        
        visit dashboard_path

        within('#lists') do
          page.find('tr:nth-child(1) td:first-child').text.must_equal list2.name
          page.find('tr:nth-child(2) td:first-child').text.must_equal list1.name
        end
      end

      it "shows 'Start Request' buttons for each list" do
        visit dashboard_path
        within("#lists") do
          all_link_with_icon('btn-primary', 'ico-basket2', 'Start Request').count.must_equal 6
        end
      end

    end
  
    it 'must display oldest orders first' do
      old_purchase_requests = create_list(:purchase_request, 6)
      new_purchase_requests = create_list(:purchase_request, 6)
      
      visit dashboard_path
      
      within('#orders') do
        old_purchase_requests.each do |pr|
          page.text.must_include pr.number
        end
      end
    end

    it "shows action buttons based on PO's state" do
      purchase_order = create(:purchase_order, state: 'open')

      visit dashboard_path
      within('#orders') do
        find_link_with_icon('btn-danger', 'ico-mail-send', 'Send')
      end

      purchase_order.sent!
      visit dashboard_path
      within('#orders') do
        find_link_with_icon('btn-inverse', 'ico-truck', 'Receive')
      end

      purchase_order.closed!
      visit dashboard_path
      within('#orders') do
        assert page.has_no_xpath?("//tr/td[contains(text(), \"#{purchase_order.number}\") and contains(text(), \"PO\")]")
      end
    end

    it "shows action buttons based on PR's state" do
      purchase_request = create(:purchase_request)
      visit dashboard_path
      within('#orders') do
        find_link_with_icon 'btn-default', 'ico-marker2', 'Count'
      end

      purchase_request.send('next')
      visit dashboard_path
      within('#orders') do
        find_link_with_icon 'btn-primary', 'ico-basket2', 'Request'
      end

      purchase_request.send('next')
      visit dashboard_path
      within('#orders') do
        find_link_with_icon 'btn-success', 'ico-cart-checkout', 'Approve'
      end

      purchase_request.send('commit')
      visit dashboard_path
      within('#orders') do
        assert page.has_no_xpath?("//tr/td[contains(text(), \"#{purchase_request.number}\") and contains(text(), \"PR\")]")
      end
    end

  end
end

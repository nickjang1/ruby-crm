require 'test_helper'

describe 'Budgets Integration' do
  before(:each) do
    @user = create(:user)
    @categories = create_list(:category, 5)
    @budgets = []
    @categories.each do |c|
      @budgets << create(:budget, category: c)
    end
    sign_in @user
  end

  it "shows budgets", js: true do
    skip "WILL FIX AFTER FINISHING PM"
    visit budgets_path
    
    @categories.each do |c|
      page.body.must_include c.name
    end
    
    @budgets.each do |b|
      page.body.must_include "$#{b.amount}"
    end
  end
  
  it "adds budgets", js: true do
    skip "WILL FIX AFTER FINISHING PM"
    visit budgets_path
    assert page.has_content? 'Budget'
    
    find_button_with_icon('btn-primary', 'ico-plus-circle2', 'Add Budget Item').trigger(:click)
    page.has_css?('h4.semibold.text-primary', text: 'Add Budget Item')
    
    page.has_content?('Add Budget Item')
    click_button('Save Budget')
    page.has_css?('li.parsley-required', text: 'Amount is required.')
    
    fill_in('budget_amount', with: '123123')
    select "May", :from => "budget_month"
    click_button 'Save Budget'
    
    if page.has_content? 'May'
      page.has_content?('$123123.00', count: @categories.count)
    else
      click_link '<'
      page.has_content?('May')
      page.has_content?('$123123.00', count: @categories.count)
    end
  end
  
  it "adds budget on next year and show it", js: true do
    skip "WILL FIX AFTER FINISHING PM"
    Timecop.travel(Time.local(2014,11,14)) { visit budgets_path }
    assert page.has_content?('Budget')
    
    click_link '>'
    click_link '>'
    assert page.has_content?('2015')

    find_button_with_icon('btn-primary', 'ico-plus-circle2', 'Add Budget Item').trigger(:click)
    page.has_css?('h4.semibold.text-primary', text: 'Add Budget Item')
    fill_in('budget_amount', with: '123123')
    select "May", :from => "budget_month"
    click_button 'Save Budget'
    
    assert !page.has_content?('$123123')
    
    click_link '<'
    click_link '<'
    assert page.has_content?('2014')
    
    assert !page.has_content?('$123123', count: @categories.count)
  end
  
  it 'updates budget', js: true do
    skip "WILL FIX AFTER FINISHING PM"
    visit budgets_path
    assert page.has_content? 'Budget'
    
    find("#budgets-table .budget-item[data-budget-id=\"#{@budgets[0].id}\"]").trigger(:click)
    page.has_css?('h4.semibold.text-primary', text: 'Edit Budget Item')    
    page.has_content?('Edit Budget Item')
    
    fill_in('budget_amount', with: '12')
    select "March", :from => "budget_month"
    click_button 'Save Budget'
    
    if page.has_content? 'March'
      assert page.has_content?('$12.00')
    else
      click_link '<'
      assert page.has_content?('May')
      assert page.has_content?('$12.00')
    end
  end
  
  it 'deletes budget', js: true do
    skip "WILL FIX AFTER FINISHING PM"
    visit budgets_path
    assert page.has_content? 'Budget'
    
    find("#budgets-table .budget-item[data-budget-id=\"#{@budgets[0].id}\"]").trigger(:click)
    page.has_css?('h4.semibold.text-primary', text: 'Edit Budget Item')    
    page.has_content?('Edit Budget Item')
    
    click_link 'Delete Budget'
    
    sleep 3
    assert !page.has_css?("#budgets-table .budget-item[data-budget-id=\"#{@budgets[0].id}\"]")
  end
end

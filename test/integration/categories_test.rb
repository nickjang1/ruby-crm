require 'test_helper'

describe 'Categories Integration' do
  before do
    sign_in create(:user)
  end

  it "creating new category and checking it's edit page after that", js: true do
    items = create_list(:item, 5)
    visit new_category_path

    fill_in('New Category', with: 'Categ 1')
    sleep 2
    assert page.has_css?('#included table tbody tr', count: 1, text: 'No data available in table')
    assert page.has_css?('#excluded table tbody tr', count: 5)

    # adding couple of items:
    find(".test-item-#{items[0].id} .add_btn").trigger('click')
    assert page.has_css?(".test-item-#{items[0].id} .remove_btn")
    assert !page.has_css?(".test-item-#{items[0].id} .add_btn")
    
    find(".test-item-#{items[1].id} .add_btn").trigger('click')
    
    assert page.has_css?('#included table tbody tr', count: 2)
    assert page.has_css?('#excluded table tbody tr', count: 3)
    click_button 'Create Category'

    flash_messages[0].must_include "Category was successfully created"
    click_link 'Categ 1'

    assert page.has_css?('#included table tbody tr', count: 2)
    assert page.has_css?('#excluded table tbody tr', count: 3)
    #removing one item:
    find(".test-item-#{items[1].id} .remove_btn").trigger('click')
    assert page.has_css?('#included table tbody tr', count: 1)
    assert page.has_css?('#excluded table tbody tr', count: 4)
    click_button 'Update Category'

    page.has_content?("Category Categ 1 was successfully updated").must_equal true
    
    click_link 'Categ 1'

    assert page.has_css?('#included table tbody tr', count: 1)
    assert page.has_css?('#excluded table tbody tr', count: 4)
  end
end

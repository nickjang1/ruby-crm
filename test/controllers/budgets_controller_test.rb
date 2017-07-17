require 'test_helper'

describe BudgetsController do
  include Devise::TestHelpers

  let(:user){ create(:user) }
  let(:categories){ create_list(:category, 5, property: user.properties.first) }

  describe '#index' do
    before(:each) do
      sign_in user
      @budget = create(:budget)
      categories.each do |c|
        c.budgets << create(:budget)
      end
    end
    
    it 'should list budgets for the current month & year' do
      get :index
      assigns[:budgets].length.must_equal 6
    end
    
    it 'should create budget' do
      post :create, budget: {amount: 322, month: Date.today.month, year: Date.today.year, categories: [categories.first.id]}
      response.body.must_include '322'
      response.body.must_include Date.today.month.to_s
      response.body.must_include Date.today.year.to_s
      response.body.must_include categories.first.id.to_s
    end
    
    it 'should edit budget' do
      get :edit, id: @budget.id, format: :json
      response.body.must_include @budget.amount.to_s
      put :update, id: @budget.id, budget: {month: 1, year: Date.today.year, amount: 3000}
      updated = JSON.parse(response.body)
      updated['budgets'][0]['id'].must_equal @budget.id
      updated['budgets'][0]['amount'].must_equal '3000.0'
      updated['budgets'][0]['month'].must_equal 1
      updated['budgets'][0]['year'].must_equal Date.today.year
      updated['old_month'].must_equal Date.today.month
    end
    
    it 'should delete budget' do
      original_id = @budget.id
      delete :destroy, id: @budget.id, format: :json
      proc {
        Budget.find(original_id)
      }.must_raise(ActiveRecord::RecordNotFound)
    end
  end
  
  describe 'permission' do
    before do
      @gm = create(:user, current_property_role: Role.gm)
      @agm = create(:user, current_property_role: Role.agm)
      @manager = create(:user, current_property_role: Role.manager)
      @corporate = create(:user, current_property_role: Role.corporate)
    end
    
    it 'gm has permission to budgets page' do
      sign_in @gm
      get :index
      assert_response :success
      post :create, budget: {amount: 322, month: Date.today.month, year: Date.today.year, categories: [categories.first.id]}
      assert_response :success
    end
    
    it 'agm, coporate, manager have only index permission' do
      sign_in @manager
      get :index
      assert_response 200
      post :create, budget: {amount: 322, month: Date.today.month, year: Date.today.year, categories: [categories.first.id]}
      assert_response 302
      sign_out @manager
      
      sign_in @agm
      get :index
      assert_response 200
      post :create, budget: {amount: 322, month: Date.today.month, year: Date.today.year, categories: [categories.first.id]}
      assert_response 302
      sign_out @agm
      
      sign_in @corporate
      get :index
      assert_response 200
      post :create, budget: {amount: 322, month: Date.today.month, year: Date.today.year, categories: [categories.first.id]}
      assert_response 302
      sign_out @corporate
    end
  end
end
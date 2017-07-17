require 'minitest/autorun'
require 'test_helper'

describe Corporate::PagesController do
  include Devise::TestHelpers

  before do
    @user = create(:user)
    Property.current_id = nil
    @corporate = create(:corporate, name: "CORP1")
    @corp_user = create(:user, password: 'password', password_confirmation: 'password', corporate: @corporate, department_ids: [], current_property_role: nil)
    @prop1     = create(:property, name: 'PROPERTY1')
    @prop2     = create(:property, name: 'PROPERTY2')
    @connection1 = create(:corporate_connection, corporate: @corporate, email: @corp_user.email, property: @prop1, created_by: @user, state: :active)
    @connection2 = create(:corporate_connection, corporate: @corporate, email: @corp_user.email, property: @prop2, created_by: @user, state: :active)
    sign_in @corp_user
  end

  describe 'GET#dashboard' do
    describe 'total_spend_by_hotel chart' do
      it 'should return data for current month and 5 month before if current month is previous then May' do
        @prop1.update_attributes(created_at: Time.local(2013,11,1))
        @prop1.run_block_with_no_property do
          Timecop.travel(Time.local(2014,2,14)){ create(:item_receipt) }
          Timecop.travel(Time.local(2014,3,14)){ create(:item_receipt) }
          Timecop.travel(Time.local(2014,4,14)){ create(:item_receipt) }
        end

        Timecop.travel(Time.local(2014,4,14)) do
          get :dashboard
          assert assigns[:spend_by_hotel_data][:series].all?{|x| x[:data].count == 6 } # should return data for 6 month
        end
      end

      it 'should return data for current month and 4 month before if hotel created 5 months ago' do
        @prop1.update_attributes(created_at: Time.local(2013,12,15))
        @prop1.run_block_with_no_property do
          Timecop.travel(Time.local(2014,2,14)){ create(:item_receipt) }
          Timecop.travel(Time.local(2014,3,14)){ create(:item_receipt) }
          Timecop.travel(Time.local(2014,4,14)){ create(:item_receipt) }
        end

        Timecop.travel(Time.local(2014,4,14)) do
          get :dashboard
          puts assigns[:spend_by_hotel_data][:series].map {|x| x[:data].count }
          assert assigns[:spend_by_hotel_data][:series].all?{|x| x[:data].count == 5 } # should return data for 6 month
        end
      end

      it 'should return data for whole year if current month is May or later' do
        @prop1.update_attributes(created_at: Time.local(2013,11,1))

        Timecop.travel(Time.local(2014,8,14)) do
          get :dashboard
          assert assigns[:spend_by_hotel_data][:series].all?{|x| x[:data].count == 8 } # should return data for 8 month
        end
      end

      it 'should return correct data for spend amounts' do
        @prop1.update_attributes(created_at: Date.new(2012,12,1))
        @prop1.switch!
        Timecop.travel(Date.new(2014,3,1)) do
          create(:item_receipt)
        end
        Timecop.travel(Date.new(2014,5,1)) do
          create(:item_receipt)
        end

        @prop2.update_attributes(created_at: Time.local(2012,11,10))
        @prop2.switch!
        Timecop.travel(Date.new(2014,1,1)) do
          create(:item_receipt)
        end
        Timecop.travel(Date.new(2014,6,1)) do
          create(:item_receipt)
        end

        Property.current_id = nil

        Timecop.travel(Time.local(2014,7,14)) do
          get :dashboard

          prop1_data = assigns[:spend_by_hotel_data][:series].find{|x| x[:id] == @prop1.id}[:data]
          prop1_data[2].must_equal 50000.0
          prop1_data[4].must_equal 50000.0

          prop2_data = assigns[:spend_by_hotel_data][:series].find{|x| x[:id] == @prop2.id}[:data]
          prop2_data[0].must_equal 50000.0
          prop2_data[5].must_equal 50000.0
        end
      end
    end

  end
end

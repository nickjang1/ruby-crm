require 'minitest/autorun'
require 'test_helper'

describe FaxController do
  include Devise::TestHelpers

  let(:user){ create(:user) }

  before do
    sign_in user
  end

  describe '#create' do
    before do
      @vendor   = FactoryGirl.create(:vendor, property: user.all_properties.first, fax: 'test-number')
      @order    = FactoryGirl.create(:purchase_order, vendor: @vendor, state: 'open')
    end

    it 'should create a worker' do
      post :create, id: @order.id
      assert_equal 1, FaxWorker.jobs.size
      FaxWorker.drain
      assert_equal 0, FaxWorker.jobs.size

      @order.reload
      @order.fax_last_status.must_equal 'failed'
    end

    it 'should success to send fax' do
      skip "FIX LATER, IT'S WORKING ON LOCAL, BUT NOT WORKING ON CIRCLECI"
      @order.vendor.fax = '+19193770445'
      @order.vendor.save

      post :create, id: @order.id
      FaxWorker.drain

      @order.reload
      @order.fax_last_status.must_equal 'sending'
    end
  end

end

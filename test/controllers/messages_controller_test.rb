require 'minitest/autorun'
require 'test_helper'

describe MessagesController do
  include Devise::TestHelpers
  include UsesTempFiles
  
  ATTACHMENT_TEMP_FILE = 'attachment.txt'
  
  in_directory_with_file(ATTACHMENT_TEMP_FILE)


  let(:user){ create(:user) }

  describe 'test with attachment' do
    before do
      sign_in create(:user)
      @pr = create(:purchase_request, :with_items)
      content_for_file('this is test file')
    end

    it 'should add message' do
      post :create, model_id: @pr.id, body: 'test message', model_type: 'PurchaseRequest'
      post :create, model_id: @pr.id, body: 'test message with attachment', model_type: 'PurchaseRequest', attachment: uploaded_file_object(Message, :attachment, File.open(ATTACHMENT_TEMP_FILE))
      
      get :index, model_id: @pr.id, model_type: 'PurchaseRequest'
      messages = JSON.parse(response.body)
      messages.count.must_equal 2
      messages[1]['body'].must_equal 'test message'
      messages[1]['attachment_exist'].must_equal false
      messages[1]['attachment_url'].must_equal 'javascript:void(0)'
      messages[0]['body'].must_equal 'test message with attachment'
      messages[0]['attachment_exist'].must_equal true
      messages[0]['attachment_type'].must_equal 'txt'
      messages[0]['attachment_filename'].must_equal ATTACHMENT_TEMP_FILE
    end
  end

end
require "test_helper"

class MessageTest < ActiveSupport::TestCase
  include UsesTempFiles
  
  ATTACHMENT_TEMP_FILE = 'attachment.docx'
  
  in_directory_with_file(ATTACHMENT_TEMP_FILE)
  
  let(:user){ create(:user, current_property_role: Role.agm)}
  
  it 'no messages' do
    Message.count.must_equal 0
  end
  
  describe 'should insert new message with attachment' do
    before do
      content_for_file('this is test file')
    end
    
    it 'should validate body and user' do
      message = Message.new
      message.save
      message.errors.count.must_equal 2
      message.errors.full_messages[0].must_equal 'User can\'t be blank'
      message.errors.full_messages[1].must_equal 'Body can\'t be blank'
    end
    
    it 'should insert new record with attachment' do
      message = Message.new
      message.attachment = File.open(ATTACHMENT_TEMP_FILE)
      message.body = 'test message'
      message.user = user
      message.save
      
      Message.count.must_equal 1
      File.basename(message.attachment.file.path).must_equal ATTACHMENT_TEMP_FILE
      message.attachment.file.size.must_equal File.size(ATTACHMENT_TEMP_FILE)
      message.attachment.file.extension.must_equal 'docx'
      message.attachment.file.filename.must_equal 'attachment.docx'
    end
  end
end

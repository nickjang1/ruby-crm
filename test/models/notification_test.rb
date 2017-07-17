require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  before do
    @notification = create :notification
  end

  it 'must be valid' do
    @notification.valid?.must_equal true
  end
end

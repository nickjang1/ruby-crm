require 'test_helper'

describe NotificationDecorator do

  it 'must return correct link & method' do
    @notification = create(:notification, model_id: 1, ntype: 'fax.sent', message: 'Fax is successfully sent.')
    NotificationDecorator.decorate(@notification).link.must_equal "/orders/1"
    NotificationDecorator.decorate(@notification).method.must_equal "GET"
  end

end

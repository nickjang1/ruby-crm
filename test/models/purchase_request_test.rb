require 'test_helper'

describe PurchaseRequest do
  it 'must return a number based on its id' do
    purchase_request = create( :purchase_request, id: 123)
    purchase_request.number.must_equal '#00123'
  end
end

require 'test_helper'

describe Budget do
  before do
    @budget = create(:budget)
  end

  it 'must be valid' do
    @budget.valid?.must_equal true
  end
end

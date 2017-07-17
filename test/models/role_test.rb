require 'test_helper'

describe Role do
  before do
    @role = create(:role)
  end

  it 'must be valid' do
    @role.valid?.must_equal true
  end
end

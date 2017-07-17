require 'test_helper'

describe 'User Policy' do

  it 'index?' do
    check_permission(User, 'index?', 'Team')
  end

end
require 'test_helper'

describe 'Report Policy' do
  it 'index?' do
    check_permission(Report, 'index?', 'Report')
  end
end
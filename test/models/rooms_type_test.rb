require "test_helper"

describe RoomType do
  before do
    @rooms_type = RoomType.new
  end

  it "must be valid" do
    @rooms_type.valid?.must_equal true
  end
end

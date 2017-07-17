require "test_helper"

describe VendorItem do
  before do
    @vendor_item = build(:vendor_item, item: build(:item))
  end

  it "must be valid" do
    @vendor_item.valid?.must_equal true
  end

end

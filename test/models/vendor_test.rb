require "test_helper"

describe Vendor do
  it "rejects a bad email in validation" do
    vendor = build(:vendor, :email => 'Not an email')
    vendor.invalid?(:email).must_equal true
    vendor.errors[:email].first.must_equal "is not an email"
  end
end
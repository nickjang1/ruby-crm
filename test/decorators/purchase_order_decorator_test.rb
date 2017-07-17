require 'test_helper'

describe PurchaseOrderDecorator do
  it 'must return return the day it was created in USA format' do
    Timecop.freeze(Time.local(2014,1,14)) do
      po = OpenStruct.new(:created_at => Time.now)

      PurchaseOrderDecorator.new(po).created_date.must_equal '01/14/2014'
    end
  end

end

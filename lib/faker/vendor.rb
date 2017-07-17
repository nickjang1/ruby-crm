module Faker
  class Vendor < Faker::Base
    def self.name
      parse 'vendor.name'
    end
  end
end
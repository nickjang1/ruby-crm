# == Schema Information
#
# Table name: brands
#
#  id   :integer          not null, primary key
#  name :string(255)
#

class Brand < ActiveRecord::Base
  
  has_many :items
end

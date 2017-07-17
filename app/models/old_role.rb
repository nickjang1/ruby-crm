# == Schema Information
#
# Table name: roles
#
#  id          :integer          not null, primary key
#  property_id :integer
#  name        :string(255)
#  position    :integer
#  created_at  :datetime
#  updated_at  :datetime
#

class OldRole < ActiveRecord::Base
  belongs_to :property
  has_many :permissions
  
  has_and_belongs_to_many :users

  validates :name, presence: true

  scope :default, -> { where{property_id == nil} }
  scope :assigned, -> { where{property_id != nil} }

  def role=(role)
    role = find(role) unless role.kind_of? Role
    self.attributes = role.attributes.reject{|k,v| k == "id"}
  end

  def full_name
    if self.property
      self.name.prepend(self.property.name + ' - ')
    else
      self.name
    end
  end

  def self.autocomplete_source
    Role.all.collect do |r|
      {
        id: r.id,
        value: r.name,
        depth: 2,
        search: r.full_name
      }
    end.to_json
  end
end

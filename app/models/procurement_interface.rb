class ProcurementInterface < ActiveRecord::Base

  belongs_to :vendor

  serialize :data, Hash

 
  TYPE_SETTINGS = {
    vpt: {display: 'VPT (US Foods)', fields: [:partner_id, :username, :password, :division, :customer_number, :department_number, :customer_group]},
    punchout: {display: 'Punchout',fields: [:identity, :password]}
  }

  def self.types_for_select
    TYPE_SETTINGS.map{|k,v| [v[:display], k]}
  end

  def update_data_attribute(key, val)
    self.data[key] = val
    self.save
  end
end

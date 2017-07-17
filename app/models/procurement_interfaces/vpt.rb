class VPT < ProcurementInterface
  def self.setting_keys
    [:partner_id, :username, :password, :division, :customer_number, :department_number, :customer_group]
  end
end

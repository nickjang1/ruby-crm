class Punchout < ProcurementInterface
  def self.setting_keys
    [:identity, :shared_secret]
  end
end

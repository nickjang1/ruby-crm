# https://github.com/radar/paranoia/issues/37#issuecomment-13065898

module Paranoia
  # override
  def restore!
    true if self.class.unscoped.update_all({deleted_at: nil}, self.class.primary_key => id) > 0
  end
end
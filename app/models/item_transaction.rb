# == Schema Information
#
# Table name: item_transactions
#
#  id                 :integer          not null, primary key
#  item_id            :integer
#  type               :string(255)
#  change             :decimal(, )
#  purchase_step_type :string(255)
#  purchase_step_id   :integer
#  cumulative_total   :decimal(, )
#  created_at         :datetime
#  updated_at         :datetime

class ItemTransaction < ActiveRecord::Base
  belongs_to :item, counter_cache: true
  belongs_to :purchase_step, polymorphic: true

  before_create :set_item
  before_save :set_cumulative_total
  after_update :update_cumulative_total

  validates :purchase_step, :item, :associated => true
  validates :change, presence: true


  # Set the total based on the previous aggregate total
  def set_cumulative_total
    return unless self.change_changed?
    self.cumulative_total = self.change + (ItemTransaction.where(item_id: self.item_id).where{created_at < my{self.created_at || Time.current}}.order(created_at: :desc).first.try(:cumulative_total) || 0)
  end

  # Only runs for updated cumulative totals
  # Updates the next created transaction which will in turn update the next transaction (updating all more recent transactions' total)
  def update_cumulative_total
    return unless self.cumulative_total_changed?
    delta = (self.cumulative_total_change[1] || 0) - (self.cumulative_total_change[0] || 0)

    a = ItemTransaction.where("created_at > ?", self.created_at).order("created_at ASC").first
    a.update_attributes(:cumulative_total => a.cumulative_total + delta ) if a
  end

  def set_item
    self.item_id = purchase_step.item.id unless purchase_step.nil?
  end
end


#t.change + (ItemTransaction.where(item_id: t.item_id).where{created_at < t.created_at}.order(created_at: :desc).first.try(:cumulative_total) || 0)

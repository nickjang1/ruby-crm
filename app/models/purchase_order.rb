# == Schema Information
#
# Table name: purchase_orders
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  purchase_request_id :integer
#  vendor_id           :integer
#  sent_at             :datetime
#  closed_at           :datetime
#  created_at          :datetime
#  updated_at          :datetime
#  fax_id              :integer
#  fax_last_status     :string(255)
#  fax_last_message    :string(255)
#  state               :string(255)
#  property_id         :integer
#

class PurchaseOrder < ActiveRecord::Base
  belongs_to :user
  belongs_to :purchase_request
  belongs_to :vendor
  belongs_to :property

  has_many :item_orders
  has_many :purchase_receipts
  has_many :messages, as: :messagable
  accepts_nested_attributes_for :purchase_receipts

  validates :user, presence: true
  validates :purchase_request, presence: true
  validates :vendor, presence: true

  scope :closed, -> { where( state: 'closed' ) }
  scope :not_closed, -> { where.not( state: 'closed' ) }

  default_scope { where(property_id: Property.current_id) }

  # timestamp_methods :closed_at, set: :close!, unset: :open!, ask: :closed?
  # timestamp_methods :sent_at, set: :send!, unset: :unsend!, ask: :sent?

  # before_save :update_state

  # delegate :total_price, to: :purchase_request

  STATES = [:partially_received, :open, :sent, :closed]
  FAX_SENDING = 'sending'
  FAX_SUCCESS = 'success'
  FAX_FAILED  = 'failed'

  STATES.each do |state|
    define_method("#{state}?") do
      self.state.to_sym == state.to_sym
    end

    define_method("#{state}!") do
      self.state = state
      if self.has_attribute?("#{state}_at")
        write_attribute("#{state}_at", Time.now)
      end
      self.save
    end
  end

  def sent_by_fax?
    sent? && self.fax_last_status == 'success'
  end

  def sent=(value)
    value = value.to_bool if value.kind_of? String
    if value
      sent!
    else
      # unsend!
    end
  end

  def can_receive?
    sent? or partially_received? 
  end

  def send_email
    Mailer.purchase_order(self.id).deliver
  end

  def user
    User.with_deleted.find(self.user_id)
  end
  
  def number
    '#%05d' % self.id
  end

  def percent_complete
    self.item_orders.find_all(&:complete?).size / self.item_orders.size.to_f * 100
  end

  def complete?
    self.percent_complete == 100
  end

  def faxing?
    self.open? && !self.fax_last_status.blank?
  end

  def fax_error?
    self.open? && self.fax_last_status == FAX_FAILED
  end

  def fax_success?
    self.sent? && self.fax_last_status == FAX_SUCCESS
  end

  def vpt_ready?
    self.vendor.procurement_interface_enabled?(:vpt)
  end

  def update_state
    self.state = new_state unless new_state.blank?
  end

  def new_state
    if closed?
      'closed'
    elsif sent?
      'sent'
    elsif partially_received?
      'partially_received'
    else
      'open'
    end
  end

  def total_price
    return Money.new(0) if self.item_orders.empty?

    Money.new(item_orders.map(&:total).reduce(&:+) * 100 )
    #return Money.new(item_orders.select('sum(item_orders.price * item_orders.quantity) as total_price')[0][:total_price] * 100 )
  end

  def vpt_prepare
    if self.vpt_ready?
      self.vendor.procurement_interface.update_data_attribute(:vpt_request_id, Time.now.to_i)
    else
      # send error messages
      false
    end
  end
end

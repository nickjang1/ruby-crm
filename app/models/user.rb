class User < ActiveRecord::Base
  acts_as_paranoid
  acts_as_voter

  include StampUser

  devise :database_authenticatable, :recoverable, :trackable, :validatable, :confirmable, authentication_keys: [:login]
  mount_uploader :avatar, AvatarUploader
  serialize :settings, Hash

  belongs_to :corporate
  belongs_to :created_by_user, class_name: 'User' 
  has_and_belongs_to_many :old_roles

  has_many :user_roles
  has_many :roles, through: :user_roles

  has_many :properties, through: :user_roles
  has_one :current_property_user_role, class_name: 'UserRole'
  has_one :current_property_role, through: :current_property_user_role, source: :role
  delegate :title, to: :current_property_user_role, allow_nil: true
  delegate :title=, to: :current_property_user_role, allow_nil: true
  delegate :order_approval_limit, to: :current_property_user_role, allow_nil: true
  delegate :order_approval_limit=, to: :current_property_user_role, allow_nil: true

  has_many :report_favoritings
  has_many :favorite_reports, through: :report_favoritings, source: :report
  has_many :departments_users
  has_many :departments, through: :departments_users
  has_many :categories, through: :departments
  has_many :notifications
  has_many :purchase_orders
  has_many :purchase_requests
  has_many :budgets
  has_many :engage_messages, class_name: 'Engage::Message', foreign_key: :created_by_id
  has_many :engage_entities, class_name: 'Engage::Entity', foreign_key: :created_by_id
  # has_many :permissions, -> (user) { where(role_id: user.roles.first.try(:id)) }, through: :departments
  # has_many :permission_attributes, through: :permissions

  accepts_nested_attributes_for :current_property_user_role

  validates :name, presence: true
  # validates :order_approval_limit, presence: true
  validates :current_property_user_role, presence: true, if: lambda{ !!Property.current_id }
  validate :at_least_one_department, if: lambda{ !!Property.current_id }
  validate :email_or_username_exists
  validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, multiline: true
  validates :username, uniqueness: {case_sensitive: false}, allow_nil: true, allow_blank: true

  attr_accessor :login

  def at_least_one_department
    errors.add :department_ids, 'at least one should be selected' if department_ids.empty?
  end
  
  # Overwrite only_deleted, pending resolution of https://github.com/radar/paranoia/issues/62
  scope :active, -> { where(deleted_at: nil) }
  scope :corporate, -> { where.not(corporate_id: nil) }
  scope :by_roles_and_departments, -> (roles, departments) {
    joins(:current_property_role).joins(:departments)
      .where(current_property_role: {id: roles})
      .where(departments: {id: departments}).active.distinct
  }

  # override default scope of acts_as_paranoid
  def self.default_scope
  end

  def permissions
    Permission.where(role_id: roles.first.try(:id), department_id: departments.pluck(:id).uniq)
  end

  def permission_attributes
    PermissionAttribute.where(id: permissions.pluck(:permission_attribute_id))
  end

  def wo_assignable_id
    (permission_attributes.assignable.count > 0) ? self.id : Maintenance::WorkOrder::UNASSIGNED
  end

  def permitted_permissions(subject)
    permissions.by_attribute_subject subject
  end

  def active_for_authentication?
    super && !deleted_at
  end

  def deleted?
    !!deleted_at
  end

  def name_with_status
    "#{name} #{'(inactive)' if deleted?}"
  end

  def inactive_message
    deleted? ? :deleted : super
  end

  def activate!
    self.restore!
    self.email.gsub! 'inactive_', '' if self.email.present?
    self.username.gsub! 'inactive_', '' if self.username.present?
    role = self.user_roles.only_deleted.where(property_id: Property.current).last
    role.restore!
  end

  def code
    "%05d" % id
  end

  def inactivate!
    user_roles.where(property_id: Property.current).destroy_all
    if UserRole.unscoped.where(deleted_at: nil, user_id: self.id).count == 0
      self.email = "inactive_" + self.email if self.email.present?
      self.username = "inactive_" + self.username if self.username.present?
      self.save
      self.destroy
    end
  end

  def default_hotel_name
    all_properties.first.name
  end

  def first_name
    first, last = name.split(' ')
    first
  end

  def first_name_last_initial
    first, last = name.split(' ')
    "#{first} #{last[0].upcase}."
  end

  def email_required?
    false
  end

  def password_required?
    super if confirmed?
  end

  def password_match?
    self.errors[:password] << "can't be blank" if password.blank?
    self.errors[:password_confirmation] << "can't be blank" if password_confirmation.blank?
    self.errors[:password_confirmation] << "does not match password" if password != password_confirmation
    password == password_confirmation && !password.blank?
  end

  def corporate?
    !Property.current_id && corporate_id?
  end

  def maintenance_department?
    departments.pluck(:name).include? 'Maintenance'
  end

  def frontdesk_department?
    departments.pluck(:name).include? 'Front Desk'
  end

  def all_properties
    Property.where(id: UserRole.unscoped.where(user_id: self.id).active.pluck(:property_id)).order(:name)
  end

  def current_property
    return nil unless current_property_user_role.present?
    current_property_user_role.property
  end

  def pusher_id
    "#{Rails.env}_#{id}"
  end

  def pendo_visitor_id
    "#{name}_#{title}_#{email}".gsub(/\s+/, '')
  end

  def pendo_account_id
    if corporate?
      "#{name}_#{corporate.name}"
    else
      "#{name}_#{Property.current.name}"
    end.gsub(/\s+/, '')
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    elsif conditions.has_key?(:username) || conditions.has_key?(:email)
      where(conditions.to_h).first
    end
  end

  private

  def email_or_username_exists
    if email.blank? && username.blank?
      errors.add(:email, "Email or Username is required")
      errors.add(:username, "Email or Username is required")
    end
  end
end

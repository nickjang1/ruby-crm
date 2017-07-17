# == Schema Information
#
# Table name: properties
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  contact_name   :string(255)
#  street_address :string(255)
#  zip_code       :string(255)
#  city           :string(255)
#  email          :string(255)
#  phone          :string(255)
#  fax            :string(255)
#

class Property < ActiveRecord::Base
  acts_as_commentable

  has_many :user_roles
  has_many :join_invitations, as: :targetable
  has_many :users, through: :user_roles
  has_many :gm_roles, -> { where(role_id: Role.gm.id)}, class_name: UserRole
  has_many :gms, through: :gm_roles, class_name: User, source: :user

  has_many :tags
  has_many :categories
  has_many :items
  has_many :locations
  has_many :lists
  has_many :vendors
  has_many :departments
  has_many :purchase_orders
  has_many :purchase_requests
  has_many :purchase_receipts
  has_many :permissions
  has_many :alarms

  # maintenance part
  has_many :maintenance_cycles, :class_name => 'Maintenance::Cycle'
  has_many :maintenance_rooms, :class_name => 'Maintenance::Room'
  has_many :maintenance_public_areas, :class_name => 'Maintenance::PublicArea'
  has_many :maintenance_records, :class_name => 'Maintenance::MaintenanceRecord'

  has_one :corporate_connection, -> { where.not(state: Corporate::Connection::REJECTED_STATES) }, class_name: Corporate::Connection
  has_one :corporate, -> { where('corporate_connections.state = ?', :active) }, through: :corporate_connection

  serialize :settings, Hash

  validates :name, presence: true
  has_many :room_types

  def highest_gm_approval_limit
    Role.gm.user_roles.order(order_approval_limit: :desc).limit(1).pluck(:order_approval_limit).first
  end

  def proper_approvers total_price, current_user_id
    Role.gm.user_roles.where('order_approval_limit > ? and user_id != ?', total_price.to_f, current_user_id).includes(:user).map(&:user)
  end

  def setting
    settings || {}
  end

  def target_inspection_percent
    setting[:target_inspection_percent].to_i || 10
  end

  def target_inspection_rate
    target_inspection_percent / 100.0
  end

  def target_inspection_count
    (target_inspection_rate * maintenance_rooms.count).round
  end

  class << self
    def current_id=(id)
      RequestStore.store[:property_id] = id
    end

    def current_id
      RequestStore.store[:property_id]
    end

    def current
      Property.find(current_id) if current_id
    end

    def current_time
      Time.now.in_time_zone(Property.current.time_zone)
    end

    def current_time_zone
      ActiveSupport::TimeZone[Property.current.time_zone]
    end
  end

  def switch!
    Property.current_id = self.id
    self
  end

  def run
    prev_property = Property.current
    self.switch!
    yield
  ensure
    Property.current_id = prev_property.try(:id)
  end

  def run_block
    prev_property = Property.current
    self.switch!
    yield
  ensure
    prev_property.switch!
  end

  def run_block_with_no_property
    self.switch!
    yield
  ensure
    Property.current_id = nil
  end

  # this method should be called manually after property has been created
  # TODO: call it automatically after property creation when we get signup process in place
  def setup_default_maintenance_categories(user)
    categories = YAML.load_file Rails.root.join("db", "maintenance_categories.yml") 
    categories.each do |category|
      parent_item = Maintenance::ChecklistItem.create(property: self, user: user, maintenance_type: :rooms, name: category[0], row_order: :last)
      category[1].each do |subcategory_name|
        parent_item.checklist_items.create(property: self, user: user, maintenance_type: :rooms, name: subcategory_name, row_order: :last)
      end
    end
  end

  # TODO: call it automaticall after property creation
  def setup_default_maintenance_public_areas(user)
    public_areas = YAML.load_file Rails.root.join("db", "maintenance_public_areas.yml")
    public_areas.each do |public_area|
      created_public_area = Maintenance::PublicArea.create(name: public_area[0], property: self, user: user, row_order: :last)
      public_area[1].each do |a|
        created_public_area.maintenance_checklist_items.create(user: user, maintenance_type: 'public areas', name: a, row_order: :last)
      end
    end
  end

  def setup_default_departments
    run_block do
      department_names = YAML.load_file Rails.root.join('db', 'departments.yml')
      Department.find_or_initialize_many(department_names.map{|name| {name: name}}, :name)
    end
  end

  def setup_default_permissions
    run_block do
      permissions = YAML.load_file Rails.root.join('db', 'permissions.yml')
      permissions.each do |permission|
        role = Role.by_name permission[:role]
        department = Department.find_or_create_by(name: permission[:department])
        attributes = []
        if permission[:attributes] == :all
          attributes = PermissionAttribute.pluck(:id, :options, :name)
          attributes.each do |attr|
            attr[1] = attr[1].map { |aa| aa[:option] == :department ? {option: aa[:option], departments: []} : aa[:option] } if attr[1] && attr[1].count > 0
          end
        else
          permission[:attributes].each do |pp|
            pa = PermissionAttribute.find_by(name: pp[:name])
            attributes.push [pa.id, pp[:options], pa.name]
          end
        end

        except = (permission[:except] || []).map { |ee| ee[:name] }
        attributes.each do |attr|
          next if except.include?(attr[2])
          new_permission = Permission.find_or_initialize_by role_id: role.id, department_id: department.id, permission_attribute_id: attr[0]
          new_permission.options = attr[1]
          new_permission.save!
        end
      end
    end
  end

  def self.create_property(corporate, options = {})
    return false if options[:name].blank? || options[:username].blank? || options[:useremail].blank?

    property = Property.new
    property.name = options[:name]
    property.time_zone = options[:time_zone]
    property.save!

    property.switch!
    property.setup_default_departments

    user_params = {
        name: options[:username],
        email: options[:useremail],
        current_property_user_role_attributes: {
            title: 'General Manager',
            order_approval_limit: 0,
            role_id: Role.gm.id,
        },
        department_ids: [Department.find_or_create_by(name: 'All').id]
    }

    user = User.find_by(email: options[:useremail])
    if user
      invitation = JoinInvitation.create(
          sender: corporate ? corporate.users.first : nil,
          invitee: user,
          targetable: property,
          params: user_params
      )
      Mailer.delay.join_invitation(invitation.id)
    else
      user = User.new
      user.update_attributes user_params
    end

    property.setup_default_maintenance_categories(user)
    property.setup_default_maintenance_public_areas(user)
    property.setup_default_permissions

    if corporate
      corp_user = corporate.users.first
      connection = corporate.connections.build email: corp_user.email, email_confirmation: corp_user.email, state: :active
      connection.created_by = corp_user
      connection.property = property
      connection.save!

      # corp_user.current_property_role = Role.corporate
      # corp_user.title = 'Corporate'
      # corp_user.order_approval_limit = 0
      # corp_user.departments << Department.find_by(name: 'All')
      # corp_user.save!
    end

    property
  end

end

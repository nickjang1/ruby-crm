class Role < ActiveRecord::Base

  has_many :permissions
  has_many :user_roles
  has_many :users, through: :user_roles

  validates :name, presence: true

  scope :for_current_property, -> { joins(:users).order(:id).distinct }

  def self.by_name(name)
    self.find_by(name: name)
  end

  #convert 'General Manager' to 'gm'  but 'Corporate' to 'corporate' etc
  def method_name
    split_role_name = self.name.split(" ")
    name = split_role_name.many? ? split_role_name.map(&:first).join : self.name
    name.downcase
  end

  ROLE_NAMES = ['General Manager', 'Asst General Manager', 'Manager', 'Corporate', 'User', 'External Tech', 'Other', 'Admin']
  #sorry for the crazyness... really wanted to be able to do Role.gm etc...
  ROLE_NAMES.each do |role_name|
    tmp_role = Role.new(name: role_name)
    define_method(tmp_role.method_name + "?") { self.name == role_name}

    self.class.instance_eval do
      define_method(tmp_role.method_name ) { self.find_by(name: role_name)}
    end
  end

end

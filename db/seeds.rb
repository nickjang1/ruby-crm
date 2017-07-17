ActionMailer::Base.delivery_method = :test
#ActionMailer::Base.delivery_method = :letter_opener

ActiveRecord::Base.transaction do
  # USERS CAN'T CUSTOMIZE THESE SO USE SEED DATA TO MANAGE THEM THESE RUN EVERY TIME
  unit_names = %W(Gallon LB Case Each Box OZ QT ML Pack Bar Cake Dozen LT LT LT Meters Inches GM KG Keg)
  Unit.find_or_initialize_many(unit_names.map{|name| {name: name}}, :name)

  roles = []
  Role.find_or_initialize_many(Role::ROLE_NAMES.map{|name| {name: name}}, :name)

  Report.find_or_initialize_many(Report::ALL_KINDS, :permalink)

  #USERS CAN CUSTOMIZE THESE SO THESE ONLY IF NO DATA IS ALREADY THERE
  hotel1 = Property.first
  hotel2 = Property.last

  unless Property.any?
    properties = [
      {
                :name => "Hotel 1",
        :contact_name => "Shaunak Patel",
      :street_address => "5625 Dillard Drive, Suite 215 B",
            :zip_code => "27518",
                :city => "Cary, NC",
               :phone => "919-854-1234",
      },
      { 
                :name => 'Hotel 2'
      }
    ]
    Property.find_or_initialize_many(properties, :name)
    hotel1 = Property.find_by(name: 'Hotel 1')
    hotel2 = Property.find_by(name: 'Hotel 2')
  end

  Property.current_id = Property.first.id

  if Property.any?
    department_names = YAML.load_file Rails.root.join('db', 'departments.yml')

    Property.find_each do |p|
      Property.current_id = p.id
      Department.find_or_initialize_many(department_names.map{|name| {name: name}}, :name)

      p.users.each do |user|
        current_role = user.current_property_role
        if current_role == Role.gm || current_role == Role.agm
          user.departments << Department.find_by_name('All')
          user.save!
        end
      end
    end
  end

  # Permission Attributes
  permission_attributes = YAML.load_file Rails.root.join('db', 'permission_attributes.yml')
  permission_attributes.each do |level1|
    pa1 = PermissionAttribute.find_or_initialize_by(level1.slice(:name, :subject, :action))
    pa1.options = level1[:options]
    pa1.save!
    level1[:items] ||= []
    level1[:items].each do |level2|
      pa2 = PermissionAttribute.find_or_initialize_by(level2.slice(:name, :subject, :action))
      pa2.parent = pa1
      pa2.options = level2[:options]
      pa2.save!

      level2[:items] ||= []
      level2[:items].each do |level3|
        pa3 = PermissionAttribute.find_or_initialize_by(level3.slice(:name, :subject, :action))
        pa3.parent = pa2
        pa3.options = level3[:options]
        pa3.save!
      end
    end
  end

  # default permissions
  permissions = YAML.load_file Rails.root.join('db', 'permissions.yml')
  if Property.any?
    Property.find_each do |property|
      property.setup_default_permissions
    end
  end

  gm_role = Role.find_by(name: 'General Manager')
  unless User.any?
    Property.current_id = hotel1.id
    h1_gm_user = User.find_or_initialize_by(email: 'gm_h1@example.com')
    h1_gm_user.current_property_role = gm_role
    h1_gm_user.departments << Department.first
    h1_gm_user.attributes = {name: 'GM User @ H1',  password: 'password'}
    h1_gm_user.skip_confirmation!
    h1_gm_user.save!

    Property.current_id = hotel2.id
    h2_gm_user = User.find_or_initialize_by(email: 'gm_h2@example.com')
    h2_gm_user.current_property_role = gm_role
    h2_gm_user.departments << Department.first
    h2_gm_user.attributes = {name: 'GM User @ H2',  password: 'password'}
    h2_gm_user.skip_confirmation!
    h2_gm_user.save!
    Property.current_id = hotel1.id
  end

  magic_tags = %W(Repair Replace Paint Touch-up Clean)
  Property.find_each do |p|
    Property.current_id = p.id
    magic_tags.each do |tag|
      t = MagicTag.find_or_initialize_by(name: tag)
      t.text = tag
      t.save!
    end
    Property.current_id = nil
  end

  # corporate user
  # User.corporate.find_each do |user|
  #   user.all_properties.find_each do |property|
  #     property.run_block do
  #       user.reload
  #       user.current_property_role = Role.corporate
  #       user.departments << Department.find_by(name: 'All')
  #       user.save!
  #     end
  #   end
  # end

  # update work order information
  Property.find_each do |p|
    Property.current_id = p.id

    Maintenance::WorkOrder.closed.find_each do |wo|
      wo.closed_at = wo.updated_at if wo.closed_at.blank?
      wo.closed_by_user_id = wo.updated_by if wo.closed_by_user_id.blank?
      wo.save
    end
  end

  admin_user = Admin.find_or_initialize_by(email: 'admin@lodgistics.com')
  admin_user.password = 'password'
  admin_user.save!

  unless Vendor.any?
    vendor_names = ["Guest Supply Sysco", "Koss Supplies LLC.", "Lang Supplies LLC.", "Towne Shipping Co.", "Larson Shipping Co.", "Bode Stuff and Misc Co.", "Crist Supplies LLC.", "Jacobs Stuff and Misc Co.", "Fay Supplies LLC.", "Champlin Supplies LLC.", "Rosenbaum Shipping Co.", "US Foods"]
    Vendor.find_or_initialize_many(vendor_names.map{|name| {name: name}}, :name, hotel1)
  end

  category_names = ["Housekeeping", "Food & Beverage", 'Maintenance']
  Property.find_each do |p|
    Property.current_id = p.id
    Category.find_or_initialize_many(category_names.map{|name| {name: name} }, :name)
  end

end #of the transaction

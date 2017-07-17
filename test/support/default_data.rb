def load_default_data
  puts 'Load default roles ...'
  Role::ROLE_NAMES.each do |role_name|
    Role.find_or_create_by(name: role_name)
  end

  puts 'Load default permission attributes ...'
  ActiveRecord::Base.transaction do
    permission_attributes = YAML.load_file Rails.root.join('test', 'support', 'data', 'permission_attributes_test.yml')
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
  end #of the transaction
end
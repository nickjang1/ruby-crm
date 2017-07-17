namespace :db do               
  desc "Migrate users from old row schema to new"   
  task :migrate_roles => :environment do
    ActiveRecord::Base.transaction do
      manager = Role.find_by(name: 'Manager')
      gm = Role.find_by(name: 'General Manager') 

      Property.all.each do |property|
        Property.current_id = property.id

        User.all.each do |user|
          old_role = user.old_roles.where(property_id: Property.current_id).first
          next unless old_role #this user didn't have a role at this property... skip and continue
          role = (old_role.name == 'General Manager') ? gm : manager
          user.roles << role 

          user.current_property_user_role.title = old_role.name
          user.current_property_user_role.save
        end
      end
    end #of the transaction
  end
end

#usage: 
#in zsh: rake 'create_hotel[PRE-BETA @ Hilton Raleigh,nikhil@lodgistics.com]'
desc "create a new hotel and associate a user"   
task :create_hotel, [:hotel_name, :email] => :environment do |t, args|
  ActiveRecord::Base.transaction do
    hotel = Property.create(name: args[:hotel_name])
    Property.current_id = hotel.id
    department = FactoryGirl.create(:department)

    user = User.find_by(email: args[:email])
    unless user
      user = FactoryGirl.create(:user, password: 'password', email: args[:email], department_ids: [department.id]) 
      user.confirm!
    end

    user.current_property_role = Role.gm

    hotel.setup_default_maintenance_categories user
    hotel.setup_default_maintenance_public_areas user
  end
end

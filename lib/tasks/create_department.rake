#usage:
#in zsh: rake 'create_department[Maintenance]'
desc 'create a new department'
task :create_department, [:department_name] => :environment do |t, args|
  ActiveRecord::Base.transaction do
    Property.find_each do |p|
      FactoryGirl.create(:department, name: args[:department_name], property_id: p.id)
    end
  end
end

class CreateDepartmentsUsers < ActiveRecord::Migration
  def change
    create_table :departments_users do |t|
      t.belongs_to :department
      t.belongs_to :user
    end
  end
end

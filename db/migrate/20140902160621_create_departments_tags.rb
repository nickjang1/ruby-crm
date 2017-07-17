class CreateDepartmentsTags < ActiveRecord::Migration
  def change
    create_table :departments_tags do |t|
      t.belongs_to :category
      t.belongs_to :department
    end
  end
end

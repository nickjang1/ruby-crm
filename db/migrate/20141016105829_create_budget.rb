class CreateBudget < ActiveRecord::Migration
  
  def change    
    create_table :budgets do |t|
      t.references :user
      t.references :category
      
      t.decimal :amount
      t.integer :month
      t.integer :year
      
      t.timestamps
    end
  end
  
end

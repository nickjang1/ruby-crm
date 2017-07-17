class CreateMessages < ActiveRecord::Migration
  def change
    create_table :request_messages do |t|
      t.references :purchase_request
      t.references :message
      
      t.timestamps
    end
    
    create_table :messages do |t|
      t.references :user
      t.references :purchaes_request
      t.string :body
      t.string :attachment

      t.timestamps
    end
  end
end

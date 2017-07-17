class ChangeItemNumberTypeToInteger < ActiveRecord::Migration
  def self.up
    execute('ALTER TABLE items ALTER COLUMN number TYPE integer USING (number::integer);')
  end

  def self.down
    change_column :items, :number, :string
  end
end

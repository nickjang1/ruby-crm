class ChangeItemNumberToAutoIncrement < ActiveRecord::Migration
  def up
    execute "CREATE SEQUENCE items_number_seq;"
    execute "ALTER TABLE items ALTER COLUMN number SET DEFAULT nextval('items_number_seq');"
    execute "SELECT setval('items_number_seq', 10000);"
  end

  def down
  end
end

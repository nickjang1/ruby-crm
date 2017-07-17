class AddPermalinkToReports < ActiveRecord::Migration
  def change
    add_column :reports, :permalink, :string
  end
end

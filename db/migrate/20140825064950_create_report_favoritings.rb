class CreateReportFavoritings < ActiveRecord::Migration
  def change
    create_table :report_favoritings do |t|
      t.references :report
      t.references :user

      t.timestamps
    end
  end
end

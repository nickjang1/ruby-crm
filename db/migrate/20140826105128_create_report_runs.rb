class CreateReportRuns < ActiveRecord::Migration
  def change
    create_table :report_runs do |t|
      t.references :user, index: true
      t.references :report, index: true
      t.references :property, index: true

      t.timestamps
    end
  end
end

class ReportFavoriting < ActiveRecord::Base
  belongs_to :report
  belongs_to :user
end

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report_run, :class => 'ReportRuns' do
    user nil
    report nil
    property nil
  end
end

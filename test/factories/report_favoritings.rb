# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report_favoriting, :class => 'ReportFavoritings' do
    report ""
    user ""
  end
end

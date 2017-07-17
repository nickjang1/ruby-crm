# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :room_type do
    average_people 1
    name "MyString"
  end
end

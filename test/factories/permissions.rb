FactoryGirl.define do
  factory :permission do
    association :role
    association :department
    association :permission_attribute
  end
end

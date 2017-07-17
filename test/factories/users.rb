FactoryGirl.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password 'password'
    password_confirmation 'password'
    confirmed_at { Time.now }
    department_ids { [FactoryGirl.create(:department).id] }
    current_property_role { Role.gm }

    trait :unconfirmed do
      confirmed_at nil
    end

  end
end

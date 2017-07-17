FactoryGirl.define do
  factory :purchase_request do
    association :user
    property { Property.first || create(:property) }
  
    trait :with_items do
      after(:create) do |pr, evaluator|
        5.times do
          pr.items << create(:item)
        end

        pr.item_requests.update_all(quantity: 1)
      end
    end
  end
end

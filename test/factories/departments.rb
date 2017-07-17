# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :department do
    sequence(:name) {|n| "dpe#{n}" } # TODO this is broken, for some reason factorygirl tries to create this twice
  end
end

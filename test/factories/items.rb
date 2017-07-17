FactoryGirl.define do
  factory :item do
    property { Property.current || Property.first || create(:property) }

    sequence :name do |n|
      adjective = ['Scrubbing', 'Washing', 'Singing', 'Tasty', 'Lovely'].sample
      noun = ['Widget', 'Gadget', 'Cake', 'Pie'].sample
      "#{adjective} #{noun} #{n}"
		end

    par_level ''

    unit {Unit.all.sample || create(:unit)}
    pack_unit {Unit.all.sample || create(:unit) }

    inventory_unit { pack_unit }
    price_unit { pack_unit }
    # purchase_unit { pack_unit }
   
    # before(:create) do |item, evaluator|
    #   item.categories << FactoryGirl.create(:category)#Category.all.sample
    # end

    categories{ [FactoryGirl.create(:category)] }

    vendor_items{ [build(:vendor_item)] }

    factory :item_with_vendor_item do
      # after(:build) do |item|
      #   item.vendor_items << build(:vendor_item)
      # end
    end
  end
end

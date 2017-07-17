require 'test_helper'

describe Maintenance::ChecklistItem do

  before do
    @user = create(:user)
    @property = create(:property)
    @maintenance_types = [:rooms, :public_areas, :equipment]
    @maintenance_types.each do |maintenance_type|
      area = create(:maintenance_checklist_item, maintenance_type: maintenance_type, name: "#{maintenance_type} Area", user: @user, property: @property)
      3.times { |i| create(:maintenance_checklist_item, maintenance_type: maintenance_type, name: "#{maintenance_type} ChecklistItem #{i + 1}", user: @user, property: @property, area_id: area.id ) }
    end
  end

  it 'should belong to correct property' do
    other_property = create(:property)
    other_property.switch!
    Maintenance::ChecklistItem.areas.count.must_equal 0
    @maintenance_types.each { |type| Maintenance::ChecklistItem.by_type(type).count.must_equal 0 }

    @property.switch!
    Maintenance::ChecklistItem.areas.count.must_equal 3
    @maintenance_types.each { |type| Maintenance::ChecklistItem.by_type(type).count.must_equal 4 }
  end

  it 'should have nested set' do
    @property.switch!
    @maintenance_types.each do |type|
      areas = Maintenance::ChecklistItem.by_type(type).areas
      areas.each do |area|
        area.checklist_items.count.must_equal 3
        area.checklist_items.map(&:area).map(&:id).must_equal [area.id] * 3
      end
    end
    Maintenance::ChecklistItem.by_type(:rooms).areas.first.checklist_items.first.area.id.wont_equal Maintenance::ChecklistItem.by_type(:public_areas).areas.first.id
  end

  it 'should validate mandatory fields' do
    checklist_item = build(:maintenance_checklist_item, name: nil, maintenance_type: nil)
    checklist_item.valid?.must_equal false
    checklist_item.errors.full_messages.must_include 'Name can\'t be blank'
    checklist_item.errors.full_messages.must_include 'Maintenance type can\'t be blank'
  end

  describe '#room_areas' do
    it 'should be sorted by area rank order' do
      @property.switch!
      room_areas = Maintenance::ChecklistItem.room_areas
      room_areas[0].update_attributes(area_row_order_position: room_areas.length - 1)
      Maintenance::ChecklistItem.room_areas.last.id.must_equal room_areas[0].id
    end
  end

  describe '#room_areas' do
    it 'should be sorted by area row order' do
      @property.switch!
      room_areas = Maintenance::ChecklistItem.room_areas
      room_areas[0].update_attributes(area_row_order_position: room_areas.length - 1)
      Maintenance::ChecklistItem.room_areas.last.id.must_equal room_areas[0].id
    end

    it 'should sort check list items by item row order' do
      @property.switch!
      room_area = Maintenance::ChecklistItem.room_areas.first
      items = room_area.checklist_items
      items[0].update_attributes(item_row_order_position: items.length - 1)
      room_area.checklist_items.rank(:item_row_order).last.id.must_equal items[0].id
    end
  end

  describe '#public_areas' do
    it 'should be sorted by public area row order' do
      @property.switch!
      create(:maintenance_checklist_item, maintenance_type: :public_areas, name: "Public Area", user: @user, public_area_id: 1, property: @property)
      public_areas = Maintenance::ChecklistItem.for_public_areas
      public_areas[0].update_attributes(public_area_row_order_position: public_areas.length - 1)
      Maintenance::ChecklistItem.for_public_areas.last.id.must_equal public_areas[0].id
    end
  end
end

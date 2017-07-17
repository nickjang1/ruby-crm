require 'test_helper'

describe Maintenance::Room do

  before do
    @user = create(:user)
    @property = create(:property)
    10.times { |i| create(:maintenance_room, floor: (i / 5) + 1, room_number: (100 * (i / 5 + 1) + i).to_s, user: @user, property: @property) }
  end

  it 'should belong to correct property' do
    property = create(:property)
    property.switch!
    Maintenance::Room.count.must_equal 0

    @property.switch!
    Maintenance::Room.count.must_equal 10
    @property.maintenance_rooms.count.must_equal 10
  end

  it 'should return rooms on floor' do
    @property.switch!
    rooms_1 = Maintenance::Room.rooms_on_floor(1)
    rooms_1.count.must_equal 5
    rooms_1.each { |room| room.room_number.start_with?('1').must_equal true }

    rooms_2 = Maintenance::Room.rooms_on_floor(2)
    rooms_2.count.must_equal 5
    rooms_2.each { |room| room.room_number.start_with?('2').must_equal true }
  end

  it 'should validates fields' do
    room1 = build(:maintenance_room, floor: nil, room_number: nil)
    room1.valid?.must_equal false
    room1.errors.full_messages.must_include 'Floor can\'t be blank'
    room1.errors.full_messages.must_include 'Room number can\'t be blank'

    room1 = create(:maintenance_room)
    room2 = build(:maintenance_room, floor: room1.floor, room_number: room1.room_number, property: room1.property)
    room3 = build(:maintenance_room, floor: room1.floor, room_number: room1.room_number.to_i + 1, property: room1.property)
    room2.valid?.must_equal false
    room2.errors.full_messages.must_include 'Room number has already been taken'
    room3.valid?.must_equal true
  end

  it 'should have multiple work orders' do
    @property.switch!
    room = create(:maintenance_room)
    work_orders = create_list(:maintenance_work_order, 5, maintainable: room)
    room.work_orders.count.must_equal 5
    work_orders.map(&:id).each { |id| room.work_orders.map(&:id).must_include id }
  end

  it 'should have multiple maintenance records' do
    @property.switch!
    room = create(:maintenance_room)
    records = create_list(:maintenance_record, 5, maintainable: room)
    room.maintenance_records.count.must_equal 5
    room.maintenance_records.map(&:id).must_equal records.map(&:id)
  end

end

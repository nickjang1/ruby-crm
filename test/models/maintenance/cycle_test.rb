require 'test_helper'

describe Maintenance::Cycle do

  before do
    @user = create(:user)
    @property = create(:property)
    cycle_types = [:room, :public_area, :equipment]
    Timecop.travel(Time.local(2014,1,1)) do
      6.times { |i| create(:maintenance_cycle, year: Date.today.year, start_month: i * 2 + 1, frequency_months: 2, cycle_type: cycle_types[i % 3],  user: @user, property: @property) }
    end
    @property.switch!
  end

  it 'should belong to correct property' do
    property = create(:property)
    property.switch!
    Maintenance::Cycle.all.count.must_equal 0

    @property.switch!
    Maintenance::Cycle.all.count.must_equal 6
    @property.maintenance_cycles.count.must_equal 6
  end

  it 'should return rooms on floor' do
    @property.switch!
    Maintenance::Cycle.by_year(2013).count.must_equal 0
    Maintenance::Cycle.by_year(2014).count.must_equal 6
    Maintenance::Cycle.by_cycle_type(:room).count.must_equal 2
    Maintenance::Cycle.by_cycle_type(:public_area).count.must_equal 2
    Maintenance::Cycle.by_cycle_type(:equipment).count.must_equal 2
  end

  it 'should check cycle is over or not' do
    @property.switch!
    Timecop.travel(Time.local(2014, 5, 1)) do
      Maintenance::Cycle.by_year(2014).map(&:is_over?).must_equal [true, true, false, false, false, false]
    end
  end

  it 'should validates mandatory fields' do
    cycle = build(:maintenance_cycle, year: nil, start_month: nil, frequency_months: nil, cycle_type: nil)
    cycle.valid?.must_equal false
    cycle.errors.full_messages.must_include 'Year can\'t be blank'
    cycle.errors.full_messages.must_include 'Frequency months can\'t be blank'
    cycle.errors.full_messages.must_include 'Start month can\'t be blank'
    cycle.errors.full_messages.must_include 'Cycle type can\'t be blank'

    cycle1 = create(:maintenance_cycle)
    cycle2 = build(:maintenance_cycle, year: cycle1.year, start_month: cycle1.start_month, property: cycle1.property)
    cycle3 = build(:maintenance_cycle, year: cycle1.year, start_month: cycle1.start_month + cycle1.frequency_months, property: cycle1.property)
    cycle2.valid?.must_equal false
    cycle3.valid?.must_equal true
    cycle2.errors.full_messages.must_include 'Start month has already been taken'
  end

  it 'should calculate days left to cycle end' do
    Timecop.travel(Date.new(2014, 1)) do
      Maintenance::Cycle.by_cycle_type(:room).first.days_to_finish.must_equal 59
    end
  end

  it 'should calculate remaining rooms for the cycle' do
    Timecop.travel(Date.new(2014, 1)) do
      cycle = Maintenance::Cycle.first
      cycle.rooms_remaining.count.must_equal 0
      create_list(:maintenance_room, 10, property: Property.current)
      cycle.rooms_remaining.count.must_equal 10
    end
  end

  describe '#generate_room_cycle' do
    describe 'ordinality_number' do
      it 'should generate first cycle with ordinality number 1' do
        Timecop.travel(Time.local(2000, 7, 1)) do
          cycle = Maintenance::Cycle.generate_first_cycle(start_month: 7, frequency: 3, cycle_type: 'room', user_id: @user.id)
          cycle.valid?.must_equal true
          cycle.ordinality_number.must_equal 1
        end
      end

      it 'should generate first cycle with ordinality number 4' do
        Timecop.travel(Time.local(2000, 10, 10)) do
          cycle = Maintenance::Cycle.generate_first_cycle(start_month: 1, frequency: 3, cycle_type: 'room', user_id: @user.id)
          cycle.valid?.must_equal true
          cycle.ordinality_number.must_equal 4
        end
      end

      it 'should save 2 when today is april, start_month is Jan and cycle frequency months is 3 months' do
        Timecop.travel(Time.local(2014, 4, 1)) do
          cycle = Maintenance::Cycle.generate_first_cycle(start_month: 1, frequency: 3, cycle_type: 'room', user_id: @user.id)
          cycle.valid?.must_equal true
          cycle.ordinality_number.must_equal 2
        end
      end

      it 'should save 2 when today is april, start_month is March and cycle frequency months is 1 month' do
        Timecop.travel(Time.local(2014, 4, 1)) do
          cycle = Maintenance::Cycle.generate_first_cycle(start_month: 3, frequency: 1, cycle_type: 'room', user_id: @user.id)
          cycle.valid?.must_equal true
          cycle.ordinality_number.must_equal 2
        end
      end
    end
  end

  describe '#rooms_remaining' do
    it 'should return remaining rooms' do
      Timecop.travel(Time.local(2014, 1)) do
        cycle = Maintenance::Cycle.first
        cycle.rooms_remaining.count.must_equal 0
        create_list(:maintenance_room, 10, property: Property.current)
        cycle.rooms_remaining.count.must_equal 10
      end
    end

    it "should not return finished rooms in current cycle when retrieve previous cycle's remaining rooms" do
      Timecop.travel(Time.local(2015, 1, 1)) do
        Maintenance::Cycle.generate_first_cycle(start_month: 1, frequency: 3, cycle_type: 'room', user_id: @user.id)
      end
      Timecop.travel(Time.local(2015, 5, 1)) do
        Maintenance::Cycle.generate_next_cycle :room
        rooms = create_list(:maintenance_room, 10, property: Property.current)
        # PM 5 rooms in previous cycle
        5.times do |i|
          create(:maintenance_record,
                 cycle: Maintenance::Cycle.previous,
                 maintainable_id: rooms[i].id,
                 maintainable_type: 'Maintenance::Room',
                 status: Maintenance::MaintenanceRecord::STATUS_FINISHED,
                 completed_on: (Date.today - 5.days))
        end

        Maintenance::Cycle.previous.rooms_remaining.count.must_equal 5
        # PM all rooms in current cycle
        10.times do |i|
          create(:maintenance_record,
                 cycle: Maintenance::Cycle.current,
                 maintainable_id: rooms[i].id,
                 maintainable_type: 'Maintenance::Room',
                 status: Maintenance::MaintenanceRecord::STATUS_FINISHED,
                 completed_on: (Date.today - 5.days))
        end

        Maintenance::Cycle.previous.rooms_remaining.count.must_equal 0
      end
    end
  end

  describe '#public_areas_remaining' do
    it 'should return remaining public areas' do
      Timecop.travel(Time.local(2014, 1)) do
        cycle = Maintenance::Cycle.current(:public_area)
        cycle.public_areas_remaining.count.must_equal 0
        create_list(:maintenance_public_area, 10, property: Property.current)
        cycle.public_areas_remaining.count.must_equal 10
      end
    end

    it "should not return finished public areas in current cycle when retrieve previous cycle's remaining public areas" do
      Timecop.travel(Time.local(2015, 1, 1)) do
        Maintenance::Cycle.generate_first_cycle(start_month: 1, frequency: 3, cycle_type: 'public_area', user_id: @user.id)
      end
      Timecop.travel(Time.local(2015, 5, 1)) do
        Maintenance::Cycle.generate_next_cycle :public_area
        public_areas = create_list(:maintenance_public_area, 10, property: Property.current)
        # PM 5 public areas in previous cycle
        5.times do |i|
          create(:maintenance_record,
                 cycle: Maintenance::Cycle.previous(:public_area),
                 maintainable_id: public_areas[i].id,
                 maintainable_type: 'Maintenance::PublicArea',
                 status: Maintenance::MaintenanceRecord::STATUS_FINISHED,
                 completed_on: (Date.today - 5.days))
        end
        Maintenance::Cycle.previous(:public_area).public_areas_remaining.count.must_equal 5
        # PM all public areas in current cycle
        10.times do |i|
          create(:maintenance_record,
                 cycle: Maintenance::Cycle.current(:public_area),
                 maintainable_id: public_areas[i].id,
                 maintainable_type: 'Maintenance::PublicArea',
                 status: Maintenance::MaintenanceRecord::STATUS_FINISHED,
                 completed_on: (Date.today - 5.days))
        end

        Maintenance::Cycle.previous(:public_area).public_areas_remaining.count.must_equal 0
      end
    end
  end

  it 'should generate next cycle if current cycle is over' do
    Timecop.travel(Time.local(2015, 1, 1)) do
      cycle = Maintenance::Cycle.generate_first_cycle(start_month: 1, frequency: 3, cycle_type: 'room', user_id: @user.id)
      cycle.valid?.must_equal true
      cycle.ordinality_number.must_equal 1
    end

    Timecop.travel(Time.local(2015, 4, 1)) do
      new_cycle = Maintenance::Cycle.generate_next_cycle :room
      new_cycle.start_month.must_equal 4
      new_cycle.ordinality_number.must_equal 2
    end

    Timecop.travel(Time.local(2015, 1, 1)) do
      new_cycle = Maintenance::Cycle.generate_next_cycle :room
      new_cycle.ordinality_number.must_equal 2
      new_cycle.start_month.must_equal 4
    end
  end

  it 'start month: Jan, frequency: 1, current month: Jan' do
    puts 'start month: Jan, frequency: 1, current month: Jan'
    Timecop.travel(Time.local(2015, 1, 1)) do
      cycle = Maintenance::Cycle.generate_first_cycle(start_month: 1, frequency: 1, cycle_type: 'room', user_id: @user.id)
      cycle.valid?.must_equal true
      cycle.ordinality_number.must_equal 1
      log_cycle cycle
    end

    (1..22).each do |i|
      Timecop.travel(Date.new(2015, 1, 1) + i.months) do
        new_cycle = Maintenance::Cycle.generate_next_cycle :room
        new_cycle.ordinality_number.must_equal i.modulo(12) + 1
        month = 1 + i
        year = month > 12 ? month / 12 : 0
        month = month > 12 ? month.modulo(12) : month
        new_cycle.start_month.must_equal month
        new_cycle.year.must_equal 2015 + year

        log_cycle new_cycle
      end
    end
  end

  it 'start month: Feb, frequency: 1, current month: April' do
    puts 'start month: Feb, frequency: 1, current month: April'
    Timecop.travel(Time.local(2015, 4, 1)) do
      cycle = Maintenance::Cycle.generate_first_cycle(start_month: 2, frequency: 1, cycle_type: 'room', user_id: @user.id)
      cycle.valid?.must_equal true
      cycle.ordinality_number.must_equal 3
      log_cycle cycle
    end

    (1..19).each do |i|
      Timecop.travel(Date.new(2015, 4, 1) + i.months) do
        new_cycle = Maintenance::Cycle.generate_next_cycle :room
        log_cycle new_cycle
        new_cycle.ordinality_number.must_equal (2 + i).modulo(12) + 1
        month = 4 + i
        year = month > 12 ? month / 12 : 0
        month = month > 12 ? month.modulo(12) : month
        new_cycle.start_month.must_equal month
        new_cycle.year.must_equal 2015 + year
      end
    end
  end

  it 'start month: Jan, frequency: 2, current month: Jan' do
    puts 'start month: Jan, frequency: 2, current month: Jan'
    Timecop.travel(Time.local(2015, 1, 1)) do
      cycle = Maintenance::Cycle.generate_first_cycle(start_month: 1, frequency: 2, cycle_type: 'room', user_id: @user.id)
      cycle.valid?.must_equal true
      cycle.ordinality_number.must_equal 1

      log_cycle cycle
    end

    (1..10).each do |i|
      Timecop.travel(Date.new(2015, 1, 1) + (i * 2).months) do
        new_cycle = Maintenance::Cycle.generate_next_cycle :room
        log_cycle new_cycle
        new_cycle.ordinality_number.must_equal i.modulo(6) + 1
        month = 1 + i * 2
        year = month > 12 ? month / 12 : 0
        month = month > 12 ? month.modulo(12) : month
        new_cycle.start_month.must_equal month
        new_cycle.year.must_equal 2015 + year
      end
    end
  end

  it 'start month: Feb, frequency: 2, current month: 2' do
    puts 'start month: Feb, frequency: 2, current month: Feb'
    Timecop.travel(Time.local(2015, 2, 1)) do
      cycle = Maintenance::Cycle.generate_first_cycle(start_month: 2, frequency: 2, cycle_type: 'room', user_id: @user.id)
      cycle.valid?.must_equal true
      cycle.ordinality_number.must_equal 1

      log_cycle cycle
    end

    (1..10).each do |i|
      Timecop.travel(Date.new(2015, 2, 1) + (i * 2).months) do
        new_cycle = Maintenance::Cycle.generate_next_cycle :room
        log_cycle new_cycle
        new_cycle.ordinality_number.must_equal i.modulo(6) + 1
        month = 2 + i * 2
        year = month > 12 ? month / 12 : 0
        month = month > 12 ? month.modulo(12) : month
        new_cycle.start_month.must_equal month
        new_cycle.year.must_equal 2015 + year
      end
    end
  end

  it 'start month: Feb, frequency: 2, current month: Apr' do
    puts 'start month: Feb, frequency: 2, current month: Apr'
    Timecop.travel(Time.local(2015, 4, 1)) do
      cycle = Maintenance::Cycle.generate_first_cycle(start_month: 2, frequency: 2, cycle_type: 'room', user_id: @user.id)
      cycle.valid?.must_equal true
      cycle.ordinality_number.must_equal 2

      log_cycle cycle
    end

    (1..8).each do |i|
      Timecop.travel(Date.new(2015, 4, 1) + (i * 2).months) do
        new_cycle = Maintenance::Cycle.generate_next_cycle :room
        log_cycle new_cycle
        new_cycle.ordinality_number.must_equal (i + 1).modulo(6) + 1
        month = 4 + i * 2
        year = month > 12 ? month / 12 : 0
        month = month > 12 ? month.modulo(12) : month
        new_cycle.start_month.must_equal month
        new_cycle.year.must_equal 2015 + year
      end
    end
  end

  it 'start month: Jan, frequency: 3, current month: Jan' do
    puts 'start month: Jan, frequency: 3, current month: Jan'
    Timecop.travel(Time.local(2015, 1, 1)) do
      cycle = Maintenance::Cycle.generate_first_cycle(start_month: 1, frequency: 3, cycle_type: 'room', user_id: @user.id)
      cycle.valid?.must_equal true
      cycle.ordinality_number.must_equal 1

      log_cycle cycle
    end

    (1..6).each do |i|
      Timecop.travel(Date.new(2015, 1, 1) + (i * 3).months) do
        new_cycle = Maintenance::Cycle.generate_next_cycle :room
        log_cycle new_cycle
        new_cycle.ordinality_number.must_equal i.modulo(4) + 1
        month = 1 + i * 3
        year = month > 12 ? month / 12 : 0
        month = month > 12 ? month.modulo(12) : month
        new_cycle.start_month.must_equal month
        new_cycle.year.must_equal 2015 + year
      end
    end
  end

  it 'start month: Jan, frequency: 3, current month: Feb' do
    puts 'start month: Jan, frequency: 3, current month: Feb'
    Timecop.travel(Time.local(2015, 2, 1)) do
      cycle = Maintenance::Cycle.generate_first_cycle(start_month: 1, frequency: 3, cycle_type: 'room', user_id: @user.id)
      cycle.valid?.must_equal true
      cycle.ordinality_number.must_equal 1

      log_cycle cycle
    end

    (1..6).each do |i|
      Timecop.travel(Date.new(2015, 2, 1) + (i * 3).months) do
        new_cycle = Maintenance::Cycle.generate_next_cycle :room
        log_cycle new_cycle
        new_cycle.ordinality_number.must_equal i.modulo(4) + 1
        month = 1 + i * 3
        year = month > 12 ? month / 12 : 0
        month = month > 12 ? month.modulo(12) : month
        new_cycle.start_month.must_equal month
        new_cycle.year.must_equal 2015 + year
      end
    end
  end

  it 'start month: Feb, frequency: 3, current month: Feb' do
    puts 'start month: Feb, frequency: 3, current month: Feb'
    Timecop.travel(Time.local(2015, 2, 1)) do
      cycle = Maintenance::Cycle.generate_first_cycle(start_month: 2, frequency: 3, cycle_type: 'room', user_id: @user.id)
      cycle.valid?.must_equal true
      cycle.ordinality_number.must_equal 1

      log_cycle cycle
    end

    (1..6).each do |i|
      Timecop.travel(Date.new(2015, 2, 1) + (i * 3).months) do
        new_cycle = Maintenance::Cycle.generate_next_cycle :room
        log_cycle new_cycle
        new_cycle.ordinality_number.must_equal i.modulo(4) + 1
        month = 2 + i * 3
        year = month > 12 ? month / 12 : 0
        month = month > 12 ? month.modulo(12) : month
        new_cycle.start_month.must_equal month
        new_cycle.year.must_equal 2015 + year
      end
    end
  end

  it 'start month: Feb, frequency: 3, current month: May' do
    puts 'start month: Feb, frequency: 3, current month: May'
    Timecop.travel(Time.local(2015, 5, 1)) do
      cycle = Maintenance::Cycle.generate_first_cycle(start_month: 2, frequency: 3, cycle_type: 'room', user_id: @user.id)
      cycle.valid?.must_equal true
      cycle.ordinality_number.must_equal 2

      log_cycle cycle
    end

    (1..5).each do |i|
      Timecop.travel(Date.new(2015, 5, 1) + (i * 5).months) do
        new_cycle = Maintenance::Cycle.generate_next_cycle :room
        log_cycle new_cycle
        new_cycle.ordinality_number.must_equal (i + 1).modulo(4) + 1
        month = 5 + i * 3
        year = month > 12 ? month / 12 : 0
        month = month > 12 ? month.modulo(12) : month
        new_cycle.start_month.must_equal month
        new_cycle.year.must_equal 2015 + year
      end
    end
  end

  def log_cycle(cycle)
    puts "#{cycle.year} #{Date::MONTHNAMES[cycle.start_month]} #{cycle.ordinality_number}"
  end
end

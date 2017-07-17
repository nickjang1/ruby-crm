class Maintenance::CyclesController < Maintenance::BaseController

  def create
    @cycle = current_cycle params[:cycle_type]
    params[:user_id] = current_user.id
    if @cycle.blank?
      @cycle = Maintenance::Cycle.generate_first_cycle params if @cycle.nil?
      if @cycle.valid?
        render json: { cycle: @cycle, message: 'Cycle Frequency updated.' }, status: 200
      else
        render json: { error: @cycle.errors.full_messages.to_sentence }, status: 400
      end
    else
      render json: { error: 'You already setup cycle.' }, status: 409
    end
  end

  # post /maintenance/cycles/create_next
  # creates a next cycle record
  def create_next
    old_cycles = Maintenance::Cycle::CYCLE_TYPES.map { |type| Maintenance::Cycle.current(type) }.select{ |cycle| cycle && cycle.is_over? }
    cycles = []
    for old_cycle in old_cycles
      cycles << Maintenance::Cycle.generate_next_cycle( old_cycle.cycle_type )
    end
    flash[:sticky_messages] = []
    render json: cycles.map{|cycle| {cycle_number: cycle.ordinality_number, cycle_type: cycle.cycle_type_desc, year: cycle.year } }.to_json
  end

end

class RoomsController < ApplicationController
  unloadable
  before_filter :set_floor
  before_filter :set_room, only: [:show, :edit, :update, :destroy]

  def index
    @rooms = @floor.rooms.ordered
    redirect_to quick_new_floor_rooms_path(@floor) if @rooms.size==0
  end

  def show
  end

  def new
    @room = Room.new
  end

  def create
    @room = Room.new
    @room.floor = @floor
    if @room.update_attributes(params[:room])
      @json ? render_json_room : redirect_to(floor_rooms_path(@floor), notice: 'Помещение изменено.')
    else
      @json ? render_json_room_error : render(:edit)
    end
  end

  def edit
  end

  def update
    #@place.safe_attributes = params[:place]
    if @room.update_attributes(params[:room])
      @json ? render_json_room : redirect_to(floor_rooms_path(@floor), notice: 'Помещение изменено.')
    else
      @json ? render_json_room_error : render(:edit)
    end
  end

  def destroy
    @room.destroy
    if @json
      render(json: {status: :ok}, status: :ok, location: @room)
    else
      redirect_to(floor_rooms_path(@floor), notice: 'Помещение удалено.')
    end
  end

  def quick_new
  end

  def quick_create
    rooms = params[:floor]
    rooms.each do |category, room|
      id = room[:id].to_i
      name = Room.short_rus_name(id)
      count = room[:count].to_i
      range = room[:range].gsub(/ *\- */, '-').split(' ')
      nums = []
      last_num = nil
      range.each do |num|
        case num
          when /^[0-9]+$/
            nums << num.to_i
          when /^[0-9]+\-[0-9]+$/
            nums += Range.new(*num.split('-').map(&:to_i)).to_a
          when /^[0-9]+\-$/
            last_num = num.sub('-', '').to_i
        end
      end
      last_num ||= nums.last
      if (dif = count - nums.count) > 0
        nums += Range.new(last_num, last_num+dif-1).to_a
      else
        nums = nums[0...count]
      end
      nums.each do |num|
        room = Room.new
        room.floor_id = @floor.id
        room.category = id
        room.name = "#{name} №#{num}"
        room.save
      end
    end
    redirect_to(floor_rooms_path(@floor), notice: 'Помещение удалено.')
  end

  private

  def set_floor
    @floor = Floor.find(params[:floor_id])
    @building = @floor.building
    @organization = @building.organization
    @json =  params[:ajax]&&params[:ajax]=='json'
  end

  def set_room
    @room = Room.find(params[:id])
  end

  def render_json_room
    place = {room:
                 {id: @room.id,
                  name: @room.name,
                  category: @room.category,
                  area: @room.area}
    }
    render(json: room, status: :ok, location: @room)
  end

  def render_json_place_error
    render( json: @place.errors, status: :unprocessable_entity)
  end

end
class PlacesController < ApplicationController
  unloadable
  accept_api_auth :index, :create, :update, :destroy
  before_filter :set_floor
  before_filter :set_place, only: [:show, :edit, :update, :destroy]

  def index
    @places = @floor.places.ordered
    respond_to do |format|
      format.html
      format.api { @places }
    end
  end

  def show
  end

  def new
    @place = Place.new
  end

  def edit
  end

  # POST /floor/[id]/place.json
  # {
  #   "place": {
  #     "name": 1,
  #     "category": 2,
  #     "point_x": 234,
  #     "point_y": 654
  #   }
  # }

  def create
    @place = Place.new
    @place.floor = @floor
    @place.safe_attributes = params[:place]
    if @place.save
      @json ? render_json_place : redirect_to(floor_places_path(@floor), notice: 'Добавлено новая точка на карту.')
    else
      @json ? render_json_place_error : render(:new)
    end
  end

  # PUT /floor/[id]/place/[id].json
  # {
  #   "place": {
  #     "name": 1,
  #     "category": 2,
  #     "point_x": 234,
  #     "point_y": 654
  #   }
  # }

  def update
    #@place.safe_attributes = params[:place]
    if @place.update_attributes(params[:place])
      @json ? render_json_place : redirect_to(floor_places_path(@floor), notice: 'Точка на карте изменена.')
    else
      @json ? render_json_place_error : render(:edit)
    end
  end

  def destroy
    @place.destroy
    if @json
      render(json: {status: :ok}, status: :ok, location: @place)
    else
      redirect_to(floor_places_path(@floor), notice: 'Точка на карте удалена.')
    end
  end

  private

  def render_json_place
    place = {place:
         {id: @place.id,
          name: @place.name,
          category: @place.category,
          point_x: @place.point_x,
          point_y: @place.point_y}
    }
    render(json: place, status: :ok, location: @place)
  end

  def render_json_place_error
    render( json: @place.errors, status: :unprocessable_entity)
  end

  def set_floor
    @floor = Floor.find(params[:floor_id])
    @building = @floor.building
    @organization = @building.organization
    @json =  params[:ajax]&&params[:ajax]=='json'
  end

  def set_place
    @place = Place.find(params[:id])
  end

  # def place_attributes
  #   params.require(:place).permit(:name, :category, :point)
  # end
end

class FloorsController < ApplicationController
  unloadable
  before_filter :set_floor, only: [:show, :plan, :edit, :update]
  before_filter :set_building, except: :plan
  before_filter :set_floors, only: [:show, :index]


  def index
  end

  def show
    render :index
  end

  def new
    @floor = Floor.new
  end

  def edit
  end

  def create
    unless User.current.allowed_to?(:add_floors, nil, :global => true)
      raise ::Unauthorized
    end
    set_from_params
    respond_to do |format|
      if @floor.save
        format.html { redirect_to floor_path(@floor, building: @building), notice: 'Этаж создан.' }
        format.json { render :show, status: :created, location: @floor }
      else
        format.html { render :new }
        format.json { render json: @floor.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    unless User.current.allowed_to?(:edit_floors, nil, :global => true)
      raise ::Unauthorized
    end
    set_from_params
    respond_to do |format|
      if @floor.save
        format.html { redirect_to floors_path(selected: @floor.id, building: @building), notice: 'Этаж обновлен.' }
        format.json { render :show, status: :created, location: @floor }
      else
        format.html { render :new }
        format.json { render json: @floor.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
  end

  def plan
    send_data(@floor.plan, type: 'image/svg+xml', filename: @floor.name, disposition: 'inline')
  end

  private

  def set_from_params
    @floor.building = @building
    @floor.name = params[:floor][:name]
    @floor.ord  = params[:floor][:ord]
    @floor.viewbox     = params[:floor][:viewbox]
    @floor.polygon     = params[:floor][:polygon]
    @floor.primitives  = params[:floor][:primitives]
    @floor.plan = params[:floor][:plan].read if params[:floor][:plan]
  end

  def set_floor
    @floor = Floor.find(params[:id])
  end

  def set_building
    @building = @floor ? @floor.building : Building.find(params[:building])
    @organization = @building.organization
  end

  def set_floors
    @floors = @building.floors
    @selected = params[:selected] ? @floors.find(params[:selected]) : @floors.first
    @rooms = @selected.rooms
    @places = @selected.places
    if @selected.primitives
      @primitives = @selected.primitives.lines.map do |i|
        begin
          eval(i.chomp)
        rescue Exception => exc
          nil
        end
      end
    else
      @primitives = []
    end
  end
end

#!/bin/env ruby
# encoding: utf-8
class EquipmentsController < ApplicationController
  unloadable
  include Repairs
  include EquipmentsHelper
  before_action :set_equipment, only: [:show, :edit, :update, :destroy, :new_repair]

  helper :sort
  include SortHelper

  def import
    #file_name = Dir.pwd + '/plugins/iac/db/bp.csv'
    #csv_text = File.read(file_name)
    #csv = CSV.parse(csv_text, :headers => true, :col_sep => ";")
    #fail = []
    #csv.each do |row|
    #  rh = row.to_hash
    #  main_equipment = Equipment.where("invnumber like '%#{rh['invn']}' and equipmenttype = 10002")
    #  if main_equipment.count == 1
    #    me = main_equipment.first
    #    equipment = Equipment.where("invnumber like '%#{rh['invn']}' and equipmenttype = 10014")
    #    if equipment.count < 2
    #      eq = equipment.first if equipment.count == 1
    #      if equipment.count == 0
    #        eq = Equipment.new
    #      end
    #      eq.ownerequipmentid  = me.id
    #      eq.stationname       = rh['name']
    #      eq.sernumber         = rh['sern'] if rh['sern'] != ''
    #      eq.equipmenttype  = 10014
    #      eq.ownerid        = me.ownerid
    #      eq.setplaceid     = me.setplaceid
    #      eq.isinheritedinvnumber     = 0
    #      eq.statusid       = 50002
    #      eq.getdate        = me.getdate
    #      eq.bldgaddressid  = me.bldgaddressid
    #      eq.save
    #    else
    #      fail << rh
    #    end
    #  else
    #    fail << rh
    #  end
    #end
    #render fail
  end

  # GET /equipments
  # GET /equipments.json
  def index
    # Добавляем в фильтр ид-проекта
    query = Equipment.includes(:service_requests, :main)

    if params[:project_id]
      @project = Project.find_by_identifier(params[:project_id])
      query = query.where(setplaceid: @project.oa_id_iac)
    end

    if (@f=params[:filter])
      query = query.where("invnumber like ?", "%#{@f[:inventory]}%") unless @f[:inventory].blank?
      query = query.where("upper(sernumber) like upper(?)", "%#{@f[:serial]}%")    unless @f[:serial].blank?
      query = query.where(setplaceid: Project.find(@f[:organization]).oa_id_iac) unless @f[:organization].blank?
    else
      @f={inventory: '', serial: '', project_id: ''}
    end


    # Добавляем в фильтр с идентификатором группы
    @group_selected_id = -1
    if  params[:group_id] && params[:group_id].to_i != -1
      @equipmenttypes = []
      @group_selected_id = params[:group_id].to_i
      if @group_selected_id > 0
        EquipmentCategory.where(group_id: params[:group_id]).each {|c| @equipmenttypes << c.contentid }
      else
        EquipmentCategory.where("group_id is null").each {|c| @equipmenttypes << c.contentid }
      end
      query = query.where(equipmenttype:  @equipmenttypes)
    end



    # Добавляем в фильтр признака только основного оборудования (комплекты)
    query = query.where('ownerequipmentid is null')  if params[:main_equipment]


    sort_init 'stationname'
    sort_update %w(stationname invnumber sernumber remark statusid)
    query = query.order sort_clause

    query = query.preload(:service_requests, :status)
    @limit   = per_page_option
    @count   = query.count
    @pages   = Paginator.new @count, @limit, params['page']
    @offset  ||= @pages.offset
    @equipments = query.limit(@limit).offset(@offset)
    @groups = EquipmentCategoryGroup.all
    @organizations = Organization.all
  end

  # GET /equipments/1
  # GET /equipments/1.json
  def show
    sort_init 'stationname'
    sort_update %w(stationname invnumber sernumber remark statusid)
    if @equipment.warrantyenddate.nil? && @equipment.getdate
      @equipment.warrantyenddate = @equipment.getdate.years_since(3)
      @equipment.save
    end
    Printer.create_or_modify(@equipment) if @equipment.is_printer?
  end

  # GET /equipments/new
  def new
    equipmenttype = EquipmentCategory.get_id(params[:equipment_category])
    @main      = Equipment.where("ID = #{params[:main]}").first
    if Equipment.where(invnumber: @main.invnumber, equipmenttype: @main.equipmenttype, setplaceid: @main.setplaceid).count == 0
      @project   = Project.find_by_identifier(params[:project_id])
      @equipment = Equipment.new
      @equipment.main = @main
      @equipment.equipmenttype        = equipmenttype
      @equipment.getdate              = @main.getdate
      @equipment.invnumber            = @main.invnumber
      @equipment.isinheritedinvnumber = 0
      @equipment.statusid      = @main.statusid
      @equipment.remark        = @main.remark
      @equipment.bldgaddressid = @main.bldgaddressid
      @equipment.ownerid       = @main.ownerid
      @equipment.setplaceid    = @main.setplaceid
    else
      @equipments = Equipment.where(invnumber: @main.invnumber, equipmenttype: equipmenttype).each {|e|
        e.main = @main
        e.isinheritedinvnumber = 0
        e.save
      }
      redirect_to project_equipment_path(@project, @main), notice: 'Найдено оборудование с таким же инвентарным номером'
    end
  end

  # GET /equipments/1/edit
  def edit
  end

  def new_repair
    unless @equipment.status_repair?
      if user_can_create_repair?(@project)
        repair_new params
        redirect_to issue_path(@i), notice: 'Задача на ремонт оборудования успешно зарегистрирована'
      else
        flash.now[:error] = 'Отсутствуют права на создание заявок'
        render :show
      end
    else
      render :show
    end
  end

  def delete_repair
    @service_request  = ServiceRequest.find(params[:service_request_id])
    @equipment          = Equipment.where("ID = #{params[:id]}").first
    @project            = Project.find_by_identifier(params[:project_id])

    #@service_request.executant.delete if @service_request.executant

    Check.where(requestid: @service_request.id).each do |check|
      check.check_conclusions.clear # if srec.equipment_check_conclusions
      check.check_failure_causes.clear    # if srec.equipment_failure_causes
      if (ex = Executant.where(eqpmntcheckid: check.id).first)
        ex.delete
      end
      check.delete
    end

    if (equipment_request = @service_request.equipment_request)
      @issue = equipment_request.issue
      equipment_request.delete
      @issue.delete if @issue
    end

    @service_request.delete

    redirect_to project_equipment_path(@project, @equipment)
  end

  # POST /equipments
  # POST /equipments.json
  def create
    @project   = Project.find_by_identifier(params[:project_id])
    @main      = Equipment.find(params[:equipment][:ownerequipmentid])
    if @main.has_ibp?    &&(params[:equipment][:equipmenttype] == EquipmentCategory.get_id('ibp'))||
       @main.has_monitor?&&(params[:equipment][:equipmenttype] == EquipmentCategory.get_id('monitor'))
      @equipment = Equipment.new(equipment_params)
      respond_to do |format|
        if @equipment.save
          format.html { redirect_to project_equipment_path(@project, @main), notice: 'Terminal equipment was successfully created.' }
          format.json { render :show, status: :created, location: @equipment }
        else
          format.html { render :new }
          format.json { render json: @equipment.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to project_equipment_path(@project, @main), notice: 'Регистрация оборудования откланена'
    end
  end

  # PATCH/PUT /equipments/1
  # PATCH/PUT /equipments/1.json
  def update
    @project   = Project.find_by_identifier(params[:project_id]) if params[:project_id]
    @main      = Equipment.where(id: params[:equipment][:ownerequipmentid]).first
    respond_to do |format|
      if @equipment.update(equipment_params)
        format.html { redirect_to  my_equipment_path(@project, @equipment), notice: 'Оборудование успешно обновлено.' }
        format.json { render :show, status: :ok, location: @equipment }
      else
        format.html { render :edit }
        format.json { render json: @equipment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /equipments/1
  # DELETE /equipments/1.json
  def destroy
    @equipment.destroy
    respond_to do |format|
      format.html { redirect_to equipments_url, notice: 'Terminal equipment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def get_for_select
    @equipments = Equipment.where("invnumber like #{params[:inventory]}")
  end

  def issues_without_link
    @issues = Issue.select('*, (select equipment_id from equipment_requests where issues.id=issue_id) as request').where('tracker_id = 6').all
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_equipment
      #@equipment = Equipment.find(params[:id])
      @equipment = Equipment.find(params[:id])
      @project   = Project.find_by_identifier(params[:project_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def equipment_params
      params.require(:equipment).permit(:id, :stationname, :netusetype, :equipmenttype, :ownerid, :setplaceid, :osid,
                                        :f, :ram, :remark, :cd_dvd, :invnumber, :isinheritedinvnumber, :ciauchetnumber,
                                        :uchetname, :procesorid, :statusid, :ramtypeid, :recuuid, :dtleqtypeid,
                                        :warrantyenddate, :getdate, :manufacturedt, :hddsize, :usbports, :ipadress,
                                        :netname, :checkdate, :ownerequipmentid, :dtleqtypeidstr, :buhuchetid, :sourceid,
                                        :sernumber, :lastupdate, :lastunloaddt, :bldgaddressid, :place_id)
    end
end

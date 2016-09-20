#!/bin/env ruby
# encoding: utf-8
class OrganizationsController < ApplicationController
  menu_item :organization
  accept_api_auth :index

  unloadable
  before_action {authorize(params[:controller], params[:action], true)}
  before_action :set_organization, only: [:show, :edit, :update, :destroy]


  # GET /organizations
  # GET /organizations.json
  def index
    @organizations = Organization.preload(:organization_category, project: :custom_values).all
    #
    # preload(:custom_values)
    # if has_column?(:author)
    #   scope = scope.preload(:author)
    # end
  end

  def synchronize
    @organizations = Organization.all
    @organizations.each{|org| org.synchronize}
    render 'index'
  end

  # GET /organizations/1
  # GET /organizations/1.json
  def show

  end

  # GET /organizations/new
  def new
    @organization = Organization.new
  end

  # GET /organizations/1/edit
  def edit
  end

  # POST /organizations
  # POST /organizations.json
  def create
    @organization = Organization.new(organization_params)
    respond_to do |format|
      if @organization.save
        format.html { redirect_to organization_path(@organization), notice: 'Organization was successfully created.' }
        format.json { render :show, status: :created, location: @organization }
      else
        format.html { render :new }
        format.json { render json: @organization.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /organizations/1
  # PATCH/PUT /organizations/1.json
  def update
    respond_to do |format|
      if @organization.update(organization_params)
        format.html { redirect_to organization_path(@organization), notice: 'Организация успешно обновлена.' }
        format.json { render :show, status: :ok, location: @organization }
      else
        format.html { render :edit }
        format.json { render json: @organization.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /organizations/1
  # DELETE /organizations/1.json
  def destroy
    @organization.destroy
    respond_to do |format|
      format.html { redirect_to organizations_url, notice: 'Организация успешно удалена.' }
      format.json { head :no_content }
    end
  end

  def import
    #Формируем хаш {Код ОА => project_id}
    @cast_field_code_oa = CustomField.find_by_name('Код ОА')
    @projects = Project.joins(:custom_values).
        where("custom_values.value IS NOT NULL AND custom_values.custom_field_id = #{@cast_field_code_oa.id}").
        order("projects.name").all
    @pr = {}
    @projects.each { |item| @pr.merge! item.custom_value_for(@cast_field_code_oa).to_s => item.id }


    file_name = Dir.pwd + '/plugins/iac/db/organizations.csv'
    csv_text = File.read(file_name)
    csv = CSV.parse(csv_text, :headers => true, :col_sep => ";")
    csv.each do |row|
      rh = row.to_hash
      rh['project_id'] = @pr[rh['code']].to_i
      Organization.create!(rh,{:without_protection => true})
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_organization
      @organization = Organization.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    # В рэдмайне этот блок не нужен, т.к. тут встроенный механизм санации параметров, но оставляем для совместимости
    def organization_params
      params.require(:organization).permit(:name, :code, :address, :telefone, :employee_fio, :employee_position, :oa_id_usd, :phone_code,
                                           :district_name, :name_r, :head_name, :head_name_r, :head_short_name, :head_short_name_r,
                                           :count_of_judges, :full_time_staff)
    end
end

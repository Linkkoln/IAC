#!/bin/env ruby
# encoding: utf-8
class EquipmentCategoryGroupsController < ApplicationController
  unloadable
  before_action :set_group, only: [:show, :edit, :update, :destroy]

  def index
    @equipment_category_groups = EquipmentCategoryGroup.all
  end

  def show
  end

  def new
    @equipment_category_group = EquipmentCategoryGroup.new
    @equipment_categories = EquipmentCategory.all
  end

  def edit
    @equipment_categories = EquipmentCategory.all
  end

  def create
    @equipment_category_group = EquipmentCategoryGroup.new(equipment_category_group_params)
    respond_to do |format|
      if @equipment_category_group.save
        params[:categories].keys.map {|cid|
          @category = EquipmentCategory.find(cid)
          @category.group_id = @equipment_category_group.id
          @category.save
        }
        format.html { redirect_to action: "index", notice: 'Группа оборудования добавлена' }
        format.json { render :show, status: :created, location: @equipment_category_group }
      else
        format.html { render :new }
        format.json { render json: @equipment_category_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      EquipmentCategory.where(group_id: @equipment_category_group.id).where.not(contentid: params[:categories].keys).each{ |c|
        c.group_id = nil
        c.save
      }
      params[:categories].keys.map {|cid|
        @category = EquipmentCategory.where("(group_id !=#{@equipment_category_group.id} or group_id is null) and contentid =#{cid}").take
        if @category
          @category.group_id = @equipment_category_group.id
          @category.save
        end
      }
      if @equipment_category_group.update(equipment_category_group_params)
        format.html { redirect_to @equipment_category_group, notice: 'Группа оборудования обновлена.' }
        format.json { render :show, status: :ok, location: @equipment_category_group }
      else
        format.html { render :edit }
        format.json { render json: @equipment_category_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @equipment_category_group.destroy
    respond_to do |format|
      format.html { redirect_to equipment_category_groups_url, notice: 'Группа оборудования успешно удалена.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @equipment_category_group = EquipmentCategoryGroup.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    # В рэдмайне этот блок не нужен, т.к. тут встроенный механизм санации параметров, но оставляем для совместимости
    def equipment_category_group_params
      params.require(:equipment_category_group).permit(:name, :ord)
    end
end

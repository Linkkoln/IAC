class PrinterCategoriesController < ApplicationController
  unloadable
  before_action :set_printer_category, only: [:show, :edit, :update, :destroy]
  #before_action :set_permissions
  before_action {authorize(params[:controller], params[:action], true)}
  helper :context_menus

  def index
    @printer_categories = PrinterCategory.sorted.all
  end

  def new
    @printer_category = PrinterCategory.new
  end

  def create
    @printer_category = PrinterCategory.new
    @printer_category.safe_attributes = params[:printer_category]
    respond_to do |format|
      if @printer_category.save
        format.html { redirect_to printer_categories_path, notice: 'Категория успешно создана' }
        format.json { render :show, status: :ok, location: @printer_category }
      else
        format.html { render :edit }
        format.json { render json: @printer_category.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    @printer_category.safe_attributes = params[:printer_category]

    respond_to do |format|
      if @printer_category.save
        format.html { redirect_to printer_categories_path, notice: 'Категория принтера успешно обновлена.' }
        format.json { render :show, status: :ok, location: @printer_category }
      else
        format.html { render :edit }
        format.json { render json: @printer_category.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @printer_category.printers.count == 0
      @printer_category.destroy
      respond_to do |format|
        format.html { redirect_to printer_categories_path, notice: 'Категория принтера успешно удалена.' }
        format.json { head :no_content }
      end
    else
      @printer_category.active = 0
      if @printer_category.save
        respond_to do |format|
          format.html { redirect_to printer_categories_path, notice: 'Категория принтера помечена как неактивная.' }
          format.json { render :show, status: :ok, location: @printer_category }
        end
      end
    end

  end


  private
  # Use callbacks to share common setup or constraints between actions.
  def set_printer_category
    @printer_category = PrinterCategory.find(params[:id])
  end

  def set_permissions
    #@project = Project.find_by_identifier('permissions')
  end
end
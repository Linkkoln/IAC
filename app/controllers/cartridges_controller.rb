class CartridgesController < ApplicationController
  unloadable
  before_action { authorize(params[:controller], params[:action], true) } #Проверку общих прав надо делать обязательно до установки переменной @project
  before_action :set_issue_project #, only: [:index, :show, :edit, :update, :destroy, :context_menu, :cartridge]

  include Cartridges

  def edit
    #if true
    if @issue.common?
      # && User.current.allowed_to?(:cartridge_process_application, @project)
      @cartridge_category = params[:cartridge]
      @cartridges = @issue.cartridges
      @cartridges = @cartridges.joins(printer: :printer_category).where(printer_categories: {cartridge: params[:cartridge]})
    end
    # test = true
  end

  def update
    @restored = params[:restored]
    @killed   = params[:killed]
    @restored.each do |id, value|
      restored = value.to_i
      killed   = @killed[id].to_i
      pc = PrintersIssue.find(id)
      pc.crtr_restored = restored
      pc.crtr_killed   = killed
      pc.crtr_filled   = pc.crtr_send - restored - killed
      pc.save
    end
    redirect_to issue_path(@issue)
  end

  def receive_to_tank
    if @issue.common?
      notice = 'Общую задачу невозможно принять подобным образом'
    elsif @issue.status_id != STATUS_FORMED
      notice = 'Задачу в данном статусе невозможно перевести в статус "Принята"'
    elsif !(parent = Issue.find_by(identifier: 'all', status_id: STATUS_WORK))
      notice = 'Отсутствует общая задача в статусе "В работе"'
    else
      PrintersIssue.find_by_sql("update printers_issues set crtr_real = crtr_plan, crtr_send = crtr_plan where issue_id = #{@issue.id}")
      @issue.status_id  = STATUS_TAKEN
      @issue.start_date = Date.current
      @issue.parent_id  = parent
      @issue.save
      notice = 'Картриджи приняты в заправку'
    end
    redirect_to issue_path(@issue), notice: notice
  end

  def set_issue_project
    @issue = Issue.find(params[:id])
    @project = @issue.project
  end
end

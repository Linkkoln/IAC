#!/bin/env ruby
# encoding: utf-8
class PrintersController < ApplicationController
  unloadable
  before_action :set_project, only: [:index, :new, :create, :show, :edit, :update, :destroy, :context_menu, :cartridge]
  before_action :set_printer, only: [:show, :edit, :update, :destroy]
  before_action :authorize
  helper :context_menus

  def index
    @query   = Printer.where(project_id: @project.id).worked
    @limit   = per_page_option
    @count   = @query.count
    @pages   = Paginator.new @count, @limit, params['page']
    @offset  ||= @pages.offset
    @printers = @query.limit(@limit).offset(@offset)
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
    @printer.safe_attributes = params[:printer]
    respond_to do |format|
      if @printer.save
        format.html { redirect_to project_printers_path(@project), notice: 'Принтер успешно обновлен.' }
        format.json { render :show, status: :ok, location: @printer }
      else
        format.html { render :edit }
        format.json { render json: @printer.errors, status: :unprocessable_entity }
      end
    end
  end

  def delete
  end

  def context_menu
    #@project = Project.find(params[:project_id]) unless params[:project_id].blank?
    @ids = params[:ids]
    @printers = Printer.where(id: @ids)
    @printer = @printers.first if (@printers.size == 1)
    @can = {:edit => (@printer) || (@printers)
            #:edit => (@printer && @printer.editable?) || (@contacts && @contacts.collect{|c| c.editable?}.inject{|memo,d| memo && d}),
            #:create => (@project && User.current.allowed_to?(:add_contacts, @project)),
            #:delete => @contacts.collect{|c| c.deletable?}.inject{|memo,d| memo && d},
            #:send_mails => @contacts.collect{|c| c.send_mail_allowed? && !c.primary_email.blank?}.inject{|memo,d| memo && d}

    }
    render :layout => false
  end

  def upload
    uploaded_io = params[:picture]
    File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'w') do |file|
      file.write(uploaded_io.read)
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


    file_name = Dir.pwd + '/plugins/iac/db/printers2.csv'
    csv_text = File.read(file_name)
    csv = CSV.parse(csv_text, :headers => true, :col_sep => ";")
    csv.each do |row|
      rh = row.to_hash
      rh['project_id'] = @pr[rh['court_vin']].to_i
      Printer.create!(rh, {:without_protection => true})
    end
  end

  def export
    equipment_category_id_iac = 10004 #Принтеры
    script = ''
    Printer.all.each do |p|
      t = Organization.find_by_project_id(p.project_id)
      oa_id_iac = if t
                    t.oa_id_iac
                  else
                    0
                  end
      script = script +  "insert into TERMINALEQUIPMENT (ID, STATIONNAME, EQUIPMENTTYPE, SETPLACEID, INVNUMBER, GETDATE, SERNUMBER)" +
          " values(#{p.id}, '#{p.name}', #{equipment_category_id_iac}, #{oa_id_iac}, '#{p.inventory}', '#{p.commissioning}', '#{p.serial}');\n\r"
    end
    send_data script,
              :filename => 'script_printers.sql',
              :type => 'application/msword',
              :disposition => 'attachment'
  end

  #Формируем список принтеров в текущей заявке на заправку картриджей
  def cartridge
    @ids = params[:ids]
    new_status_id = IssueStatus.find_by_name('Новая').id
    tracker = Tracker.find_by_name('Картриджи')
    #project = Project.find_by_id(params[:project])
    # Выбрать только задачу на картриджи в состоянии 'Новая'
    unless issue = Issue.find_by(tracker_id: tracker.id, project_id: @project.id, status_id: new_status_id)
      #TODO Создать задачу с трекером 'Картриджи' в текущем проекте Назначить ответственного и Проверяющего
      issue = Issue.new({tracker_id: tracker.id, project_id: @project.id, status_id: new_status_id},{:without_protection => true})
      issue.assigned_to_id = Setting.plugin_iac['cartridge_assigned_to']
      issue.subject = 'Заправка картриджей'
      issue.author_id = User.current.id
      issue.save!
    end

    @ids.each do |printer_id|
      unless PrintersIssue.find_by(printer_id: printer_id, issue_id: issue.id)
        #Если в задаче отсутствует принтер, то надо его добавить
        PrintersIssue.create({printer_id: printer_id, issue_id: issue.id, tracker_id: tracker.id, crtr_plan: 1}, {without_protection: true})
      end
    end
    redirect_to issue_path(issue)
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_project
    id = params[:project_id] || params[:project]
    @project = Project.find(id)
  end

  def set_printer
    @printer = Printer.find(params[:id])
    @project = Project.find_by_identifier(params[:project_id])
  end



  def import_cartridges
    file_name = Dir.pwd + '/plugins/iac/db/pr_iss.csv'
    csv_text = File.read(file_name)
    issues = []
    stop = []
    csv = CSV.parse(csv_text, :headers => true, :col_sep => ";")
    csv.each do |row|
      rh = row.to_hash
      count = rh['crtr_plan']
      rh['tracker_id']   = 13
      rh['crtr_real']    = count
      rh['crtr_send']    = count
      rh['crtr_filled']  = count
      rh['crtr_restored']= 0
      rh['crtr_killed']  = 0
      rh['crtr_new']     = 0
      issues << rh['issue_id']
      if PrintersIssue.find_by(printer_id: rh['printer_id'], issue_id: rh['issue_id'])
        stop << rh
      else
        PrintersIssue.create!(rh,{:without_protection => true})
      end
    end
    stop.each{|i| puts i}
    issues.uniq!
    issues.each { |item|
      issue = Issue.find(item)
      issue.status = IssueStatus.find_by_name('Сформирована')
      issue.save
      issue.status = IssueStatus.find_by_name('Принята')
      issue.save
      issue.status = IssueStatus.find_by_name('В работе')
      issue.parent_id = 3942
      issue.save
    }
  end



end

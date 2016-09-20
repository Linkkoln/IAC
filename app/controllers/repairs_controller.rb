class RepairsController < ApplicationController
  include Ekrtf

  def synchronize
    issues = Issue.where(tracker_id: 6).includes([{equipment_request: :equipment}, :custom_values])
    issues.each do |issue|
      issue.synchronize_from_equipment_params

      # next unless issue.custom_value_for(50).to_s == '1'
      # if issue.equipment_request && issue.equipment_request.equipment && !issue.equipment_request.request_id.nil?
      #
      #   equipment = issue.equipment_request.equipment
      #   # s_request = issue.service_request
      #   # s_request.hotlineregnum = issue.cf_by_name('Номер заявки ЦCТП')
      #   # issue.custom_field_values   = {22 => equipment.invnumber}
      #   # issue.custom_field_values   = {34 => s_request.check1.problemdscrptn2} if s_request.check1
      #   serial = issue.custom_value_for(21).to_s
      #   #if serial.strip!
      #   #  issue.custom_field_values = {21 => serial}
      #   #end
      #   if serial.to_s == ''
      #     if equipment.sernumber.to_s == ''
      #       issue.custom_field_values = {21 => equipment.sernumber}
      #       issue.custom_field_values = {50 => 0}
      #     else
      #       issue.custom_field_values = {50 => 1}
      #     end
      #   elsif serial == 'б/н' &&  equipment.sernumber.to_s == ''
      #     equipment.sernumber = 'б/н'
      #     equipment.save
      #     issue.custom_field_values = {50 => 0}
      #   elsif serial.to_s == equipment.sernumber
      #     issue.custom_field_values = {50 => 0}
      #   else
      #     issue.custom_field_values = {50 => 1}
      #   end
      # else
      #   issue.custom_field_values = {50 => 1}
      # end
      issue.save_custom_field_values
      #issue.service_request.save
      #issue.save
    end
    redirect_to issues_url, notice: 'Синхронизация осуществлена успешно.'
  end

  def make_file
    issue_id = params[:id].to_i
    template = params[:file]

    @issue      = Issue.find_by_id(issue_id)
    @project_id = @issue.project_id
    @sdmt       = @issue.created_on.to_time
    @project    = Project.find_by_id(@project_id)
    @request    = @issue.equipment_request.service_request
    @check      = @request.check2 || @request.check1
    @equipment  = @request.equipment

    #Статичные переменные
    pr = {}
    common_static_variable_of_project pr, @project

    pr.merge! 'ActNum'    => @request.regnum
    pr.merge! 'year'      => @request.regyear
    pr.merge! 'ReqDate'   => @request.regdate.strftime("%d.%m.%Y") if @request.regdate # Дата Заявки
    pr.merge! 'ActDateCo7'=> @check.checkdate.strftime("%d.%m.%Y") if @check.checkdate
    pr.merge! 'DatePoruch'=> Order.order_date(@request.regdate).strftime("%d.%m.%Y")

    pr.merge! 'HardType'  => @equipment.equipment_category.name
    pr.merge! 'HardName'  => @equipment.stationname
    pr.merge! 'NumInv'    => @equipment.invnumber # Инвентарный
    pr.merge! 'NumSer'    => @equipment.sernumber # Серийный №
    pr.merge! 'YearBirth' => @equipment.getdate.year.to_s if @equipment.getdate  # Год регистрации
    pr.merge! 'warranty'  => @equipment.is_warranty_text(@request.regdate)    # cf_by_name("Гарантийный срок")

    pr.merge! 'EndStatus'  => @issue.status_write_off? ? 'неисправном' : 'исправном'
    pr.merge! 'ActDateCo8' => format_date(@issue.due_date)

    if @request.executant
      pr.merge! 'ActDateCo41' => format_date(@request.executant.senddate)
      pr.merge! 'ActDateCo42' => format_date(@request.executant.sendto_oadt)
      pr.merge! 'Garant'      => @request.executant.iswarrantyrepair==1 ? "Гарантийный":"Негарантийный"
      pr.merge! 'repairdescription' => @issue.status_write_off? ? @check.conclusion_name : @request.executant.repairdescription
    end

    if @check
      pr.merge! 'DefOut'  => @check.extdamage # Внешние повреждения
      pr.merge! 'DefSeal' => @check.stopperdamage_text
      pr.merge! 'DefSpec' => @check.problemdscrptn # cf_by_name("Проявление неисправности")
      pr.merge! 'DefType' => @check.problemdscrptn2 #cf_by_name("Установленные неисправности")
      pr.merge! 'DefProp' => @check.failure_cause_name #cf_by_name("Установленные причины")
      pr.merge! 'ChapUse' => 'невозможно' #@request.cf_by_name("Использование запчастей")
      pr.merge! 'Komplektnost'      => @check.completeness
      pr.merge! 'Usloviya'          => @check.operatingconditions_text  # cf_by_name("Условия эксплуатации")
      pr.merge! 'ResultDiagnostiki' => @check.conclusion_name # cf_by_name("Заключение")
    end

    generate_rtf_by_template pr, "repair_#{template}.rtf", "repair_#{template}-#{issue_id}.rtf"
  end

  def list_svod
    @service_requests = ServiceRequest.all
  end
end
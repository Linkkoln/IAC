module Repairs

  STATUS_NEW           = 1  # Нова
  STATUS_FORMED        = 29 # Сформирована
  STATUS_DIAGN         = 8  # Диагностика
  STATUS_PURCHASE      = 24 # Закупка
  STATUS_SUSPEND       = 4  # Приостановлено

  STATUS_COMMISSIONING = 12 # Ввод в эксплуатацию
  STATUS_CLOSE         = 5  # Закрыто

  STATUS_WRITE_OFF     = 23 # На списание
  STATUS_WRITE_OFF_USD = 32 # Cписание УСД
  STATUS_WRITTEN_OFF   = 31 # Списано

  #Новая задача на ремонт
  def repair_new (params)
    new_status_id = IssueStatus.find_by_name('Новая').id
    tracker       = Tracker.find_by_name('Ремонт')
    project       = Project.find_by_identifier(params[:project_id])
    @equipment    = Equipment.find_by_id(params[:id])
    # Создать задачу с трекером 'Ремонт' в текущем проекте Назначить ответственного и Проверяющего
    @i = Issue.new({tracker_id: tracker.id, project_id: project.id, status_id: new_status_id},{:without_protection => true})
    @i.assigned_to_id = project.oa_user.to_i
    @i.subject = 'Ремонт '+ @equipment.stationname
    @i.author_id = User.current.id
    #@i.inspector = User.current.id # При наличии следующей строчки - данная строка бессмысленна
    ServiceRequest.transaction do
      request = ServiceRequest.new {|r| r.equipmentid = @equipment.id}
      request.save
      @request = request
    end
    @i.build_equipment_request
    @i.equipment_request.equipment = @equipment
    @i.equipment_request.service_request = @request
    @i.start_date = @request.regdate
    @i.synchronize_from_equipment_params
    @i.save!
  end

  def repair_update(context)
    common(context)
    return unless @repair #Вынужденно т.к. не все задачи связаны с заявками
    new_status_id         = @ip[:status_id].to_i           unless @ip[:status_id].blank?
    @repair.regdate       = @ip[:start_date]               unless @ip[:start_date].blank?
    @repair.hotlineregnum = @ip[:custom_field_values]['1'] unless @ip[:custom_field_values].blank? || @ip[:custom_field_values]['1'].blank?

    if @sr
      if @sr[:check1] #todo Проверить права на возможность сохранения результата ремонта в том числе в зависимости от статуса
        @repair.check1.conclusion    = @sr[:check1][:conclusion]    if @repair.check1.conclusion    != @sr[:check1][:conclusion].to_i
        @repair.check1.failure_cause = @sr[:check1][:failure_cause] if @repair.check1.failure_cause != @sr[:check1][:failure_cause].to_i
        @repair.executant.isdecommission = (@sr[:check1][:conclusion].to_i!=1)
      end
      if @repair.check2 && @sr[:check2] #todo Проверить права на возможность сохранения результата ремонта в том числе в зависимости от статуса
        @repair.check2.checkdate         = @sr[:check2][:checkdate]
        @repair.check2.problemdscrptn2   = @sr[:check2][:problemdscrptn2]
        @repair.executant.isdecommission = (@sr[:check2][:conclusion].to_i!=1)
      end

      if @repair.check2 && @sr[:check2] #todo Проверить права на возможность сохранения результата ремонта в том числе в зависимости от статуса
        @repair.check2.conclusion      = @sr[:check2][:conclusion]    if @repair.check2.conclusion  != (conclusion = @sr[:check2][:conclusion].to_i)
        @repair.check2.failure_cause   = @sr[:check2][:failure_cause] if @repair.check2.failure_cause != @sr[:check2][:failure_cause].to_i
      end
    end

    # Обрабатываем переход в завершающий статус
    if new_status_id

      #Если текущий статус - списание и при этом результат первой проверки = передача в ремонт и вторая проверка отсутствует, то ...
      if status_write_off?(new_status_id)&&
          @repair.check1.conclusion == 1 &&
          @repair.check2.nil?
        # Копирование данных из первой проверки во вторую
        @repair.build_check2
        @repair.check2.cablesexist          = @repair.check1.cablesexist
        @repair.check2.docexist             = @repair.check1.docexist
        @repair.check2.packexist            = @repair.check1.packexist
        @repair.check2.stopperdamage        = @repair.check1.stopperdamage
        @repair.check2.operatingconditions  = @repair.check1.operatingconditions
        @repair.check2.problemdscrptn       = @repair.check1.problemdscrptn

        @repair.check2.checkdate       = Date.current
        @repair.check2.problemdscrptn2 = @repair.check1.problemdscrptn2
        @repair.check2.service_request = @repair
      end

      # В начальной стадии обнуляем данные результатов ремонта
      if new_status_id == STATUS_NEW || new_status_id == STATUS_FORMED
        @repair.executant.iswarrantyrepair    = nil # Признак "ГАРАНТИЙНЫЙ" ремонт: 1- Да, 0 - Нет
        @repair.executant.senddate            = nil # Дата поступления в филиал
        @repair.executant.sendto_oadt         = nil # Дата возврвта на ОА
        @repair.executant.sendtoservicecentre = nil # Дата передачи в СЦ
        @repair.executant.getdate             = nil # Дата возврата из СЦ
        #@repair.executant.isiacexecuted       = nil # Признак "исполнено самостоятельно силами ИАЦ": 1- Да, 0 - Нет
        @repair.executant.repairdescription   = nil # Краткое описание ремонтных работ
      end

      if status_end_repair?(new_status_id) # Если статус Ввод в эксплуатацию, Списание, Закрыто, Списано
        @repair.executedt = @ip[:due_date] if @ip[:due_date] # Дата завершения работ СО8
        if status_write_off?(new_status_id)
          @repair.executant.iscorrected = 0      # Состояние после ремонта: 1- исправное, 0 - неиспраное
          @repair.executant.resultid    = 230012 # Возвращено без исполнения
          @repair.rezultid              = 230002 # Заявка исполнено частично

        else # Оборудование исправно # 'Закрыта'
          @repair.executant.iscorrected = 1      # Состояние после ремонта: 1- исправное, 0 - неиспраное
          @repair.executant.resultid    = 230010 # = 230010 - работы выполнены в полном объеме
          @repair.rezultid              = 230001 # Заявка исполнена в полном объеме
        end

      else #Если статус не завершающий, то очищаем все поля
        context[:params][:issue][:due_date] = nil
        @repair.executant.iscorrected = nil
        @repair.executant.resultid    = nil
        @repair.executedt = nil
        @repair.rezultid  = nil
      end

      context[:issue].synchronize_from_equipment_params

      equipment = context[:issue].equipment_request.equipment
      #Обновляем статус оборудования в соответствии с текущим статусом
      equipment.set_status_from_issue(new_status_id)
      equipment.save

      #Дублируем данные в кастомные поля задачи

      #context[:issue].custom_field_values = {22 => equipment.invnumber,
      #                                       21 => equipment.sernumber}
      #context[:params][:issue][:custom_field_values]['22'] = equipment.invnumber
      #context[:params][:issue][:custom_field_values]['21'] = equipment.sernumber
    end
  end

  def repair_save(context)
    common(context)
    return unless @repair
    #@repair.save
    #@repair.check1.save    if @repair.check1.changed?

    # Если вернулись из стадии "списно", и существует check2, то удаляем
    if @repair.check2 && !status_write_off?(context[:params][:issue][:status_id].to_i)
      @repair.executant.eqpmntcheckid = @repair.check1.id
      @repair.executant.save
      @repair.check2.check_conclusions.clear
      @repair.check2.check_failure_causes.clear
      @repair.check2.delete
    end

    # move to service_request_after_save
    #if @repair.check2 && @repair.check2.changed?
    #  @repair.check2.save
    #  @repair.executant.eqpmntcheckid = @repair.check2.id if @repair.check2.new_record?
    #end

    # move to before_save
    #if @repair.check2 && @sr[:check2] #
    #  @repair.check2.conclusion      = @sr[:check2][:conclusion]if @repair.check2.conclusion  != (conclusion = @sr[:check2][:conclusion].to_i)
    #  @repair.check2.failure_cause   = @sr[:check2][:failure_cause] if @repair.check2.failure_cause != @sr[:check2][:failure_cause].to_i
    #end

    @repair.executant.save if @repair.executant.changed?
  end

  def common(context)
    @ip = context[:params][:issue]
    @sr = @ip[:service_request]
    @repair = context[:issue].request
  end

  def user_can_create_repair?(project)
    (User.current.allowed_to?(:repair_request_new, project) or
     User.current.allowed_to?(:repairs_manager, project))
  end

  def can_repair_start_edit?
    ((self.assigned_to_id == User.current.id)&& #Назначена текущему пользователю
        (self.status_was.name=='Новая')&&
        User.current.allowed_to?(:repairs_start_edit, self.project)) or
        User.current.allowed_to?(:repairs_manager, self.project)
  end

  def user_can_repair_exec_edit?
    !self.status_start?&&
    (User.current.allowed_to?(:repairs_exec_edit, self.project) or
    User.current.allowed_to?(:repairs_manager, self.project))
  end

  # Новая, Сформирована
  def status_start?(status_id = nil)
    status_id ||= self.status_id if self.class == Issue
    [STATUS_NEW,
     STATUS_FORMED].include?(status_id)
  end

  # На списание, Списание УСД, Списано
  def status_write_off?(status_id = nil)
    status_id ||= self.status_id if self.class == Issue
    [STATUS_WRITE_OFF,
     STATUS_WRITE_OFF_USD,
     STATUS_WRITTEN_OFF].include?(status_id)
  end

  # Ввод в эксплуатацию, Закрыто
  def status_repaired?(status_id = nil)
    status_id ||= self.status_id if self.class == Issue
    [STATUS_COMMISSIONING,
     STATUS_CLOSE].include?(status_id)
  end

  # Списание, Списано, Ввод в экспл., Закрыто
  def status_end_repair?(status_id = nil)
    status_id ||= self.status_id if self.class == Issue
    status_write_off?(status_id)||
        status_repaired?(status_id)
  end
end
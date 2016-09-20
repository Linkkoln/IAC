class ServiceRequest < CiaDatabase
  self.table_name    = "SERVICEREQUEST"
  self.primary_key   = 'id'
  self.sequence_name = 'gn_global'
  # validate :chronology
  # Проверяем что бы хронология была строго последовательной:
  # - regdate (= start_date)
  # - check1.checkdate              - >= regdate
  # - executant.senddate            - >= check1.checkdate
  # - executant.sendtoservicecentre - >= senddate
  # - executant.getdate             - >= sendtoservicecentre
  # - check2.checkdate              - >= getdate||senddate
  # - executant.sendto_oadt         - >= check2.checkdate||getdate||senddate

  # after_create     :create_sub_objects
  before_update    :update_sub_objects
  # after_update     :save_sub_objects
  after_save       :save_sub_objects
  # after_initialize :init_sub_objects
  # before_save      :update_sub_objects
  around_create    :patch_sub_objects_around_create


  belongs_to :equipment, foreign_key: 'equipmentid', inverse_of: :service_requests, autosave: false
  belongs_to :executant, autosave: true #, dependent: :destroy
  belongs_to :check1,    class_name: 'Check', inverse_of: :service_request_as_check1, autosave: true#, dependent: :destroy
  belongs_to :check2,    class_name: 'Check', inverse_of: :service_request_as_check2, autosave: true#, dependent: :destroy

  has_one  :equipment_request,         foreign_key: 'request_id', autosave: false, inverse_of: :service_request
  has_one  :service_request_equipment, foreign_key: 'requestid',  autosave: false, dependent: :destroy
  has_many :service_request_statuses,  foreign_key: 'requestid',  autosave: false, dependent: :destroy

  # Атавизм. оставлен исключительно для каскадного удаления
  has_many :check, dependent: :destroy, foreign_key: 'requestid'

  #delegate :iswarrantyrepair, # Признак "ГАРАНТИЙНЫЙ" ремонт: 1- Да, 0 - Нет
  #         to: :executant
  # Данные диагностики
  #delegate :checkdate ,  # Дата акта CO7
           #:cablesexist, # Признак наличия соединительных кабелей: 1- Да, 0- Нет
           #:docexist,    # Признак наличия документации: 1- Да, 0- Нет
           #:packexist,   # Признак наличия упаковки производителя: 1- Да, 0- Нет
           #:extdamage,   # Описание внешних повреждений
           #:stopperdamage,      # Признак наличия поврежденных пломб: 1- Да, 0- Нет
           #:operatingconditions,# Признак соответствия условий эксплуатации требованиям: 1- Да, 0- нет
           ##:problemdscrptn,     # Описание проявления неисправности
           #:problemdscrptn2,    # Описание проявления неисправности

           #:conclusions,
           #:conclusion, #Заключение
           #:conclusion=, #Заключение
           #:conclusion_name,

           #:failure_causes,
           # :failure_cause, #Причина
           # :failure_cause=, #Причина
           # :failure_cause_name,
           # :senddate, #Дата передачи в филиал
           # :resultid,# = 230010 - работы выполнены в полном объеме
           # :contractid, #Код контракта = null
           # :getdate,   # Дата 4.2
           # :isiacexecuted, #Признак "исполнено самостоятельно силами ИАЦ": 1- Да, 0 - Нет
           # :iswarrantyrepair, # Признак "ГАРАНТИЙНЫЙ" ремонт: 1- Да, 0 - Нет
           # :repairdescription, # Краткое описание ремонтных работ
           # :iscorrected, #Состояние после ремонта: 1- исправное, 0 - неиспраное
           # :isreplaced, #Признак "ЗАМЕНА оборудования": 1 да, 0 - нет
           # :executanntid, #= null Код сервисного центра (фирмы исполнителя): SERVICEPROVIDERS.ID
           # :sendto_oadt, #Дата возврвта на ОА
           # :sendtoservicecentre,
           # :checkdate=,  # Дата акта CO7
           # :cablesexist=, # Признак наличия соединительных кабелей: 1- Да, 0- Нет
           # :docexist=,    # Признак наличия документации: 1- Да, 0- Нет
           # :packexist=,   # Признак наличия упаковки производителя: 1- Да, 0- Нет
           # :extdamage=,   # Описание внешних повреждений
           # :stopperdamage=,      # Признак наличия поврежденных пломб: 1- Да, 0- Нет
           # :operatingconditions=,# Признак соответствия условий эксплуатации требованиям: 1- Да, 0- нет
           # :problemdscrptn=,     # Описание проявления неисправности
           # :problemdscrptn2=,    # Описание проявления неисправности
           # Результат ремонта

           # :senddate=, #Дата передачи в филиал
           # :resultid=,# = 230010 - работы выполнены в полном объеме
           # :contractid=, #Код контракта = null
           # :getdate=,   # Дата 4.2
           # :isiacexecuted=, #Признак "исполнено самостоятельно силами ИАЦ": 1- Да, 0 - Нет
           # :iswarrantyrepair=, # Признак "ГАРАНТИЙНЫЙ" ремонт: 1- Да, 0 - Нет
           # :repairdescription=, # Краткое описание ремонтных работ
           # :iscorrected=, #Состояние после ремонта: 1- исправное, 0 - неиспраное
           # :isreplaced=, #Признак "ЗАМЕНА оборудования": 1 да, 0 - нет
           # :executanntid=, #= null Код сервисного центра (фирмы исполнителя): SERVICEPROVIDERS.ID
           # :sendto_oadt=, #Дата возврвта на ОА
           # :sendtoservicecentre=,
           # to: :service_request_equipment_check

  protected





  def update_sub_objects
    #executant
    if !self.check1.nil? && self.check1.changed?
      self.executant.cablesexist   = self.check1.cablesexist
      self.executant.docexist      = self.check1.docexist
      self.executant.packexist     = self.check1.packexist
      self.executant.extdamage     = self.check1.extdamage
      self.executant.stopperdamage = self.check1.stopperdamage
    end

    if self.regdate_changed?
      status_reg = self.service_request_statuses.where(statusid: 440001).first
      if status_reg
        status_reg.statusdate = self.regdate
        status_reg.save
      end
    end
    # service_request_equipment_check
    # Данные диагностики
    # request.cablesexist#,          # Признак наличия соединительных кабелей: 1- Да, 0- Нет
    # request.docexist#,             # Признак наличия документации: 1- Да, 0- Нет
    # request.packexist#,            # Признак наличия упаковки производителя: 1- Да, 0- Нет
  end

  def patch_sub_objects_around_create
    # service_request
    self.invnumber             = self.equipment.invnumber
    self.equipmentbybuhuchetid = self.equipment.buhuchetid
    self.sernumber             = self.equipment.sernumber
    self.bldgaddressid         = self.equipment.bldgaddressid #, Адрес здания ОА, из которого пришла заявка
    self.institutionid         = self.equipment.setplaceid
    self.visitnecessity   = 0    # Признак необходимости выезда на объект: 1- Да, 0- Нет
    self.ishardfault      = 0    # Признак наличия неисправности в аппаратной части:abs 1- да
    self.iscomsoftfault   = 0    # Признак наличия неисправности в ОПП: 1- Да
    self.isspecsoftfault  = 1    # Признак наличия неисправности в СПП: 1- Да
    self.advicedemand     = 1    # Признак необходимости консультации: 1- Да
    self.executetype      = 550003 #Характер работы по заявке: спр.55 Ремонт оборудования
    self.wrkid            = 35710  #Администратор # Код работника ИАЦ, направившего заявку
    self.regdate   = Date.current # Дата заявки
    self.regyear   = self.regdate.year       # Год регистрации
    self.regnum    = (ServiceRequest.where(regyear: self.regyear, institutionid: self.institutionid).maximum(:regnum)||0)+1      # Номер производства
    # self.shortremark      = null
    # self.declarantlevelid = null #= 430002 (Администратор суда)
    # self.chargewrkid      = null # Код работника, направленного для исполнения заявки
    # self.contentid        = null #Код контента заявки в БД CIADOC
    # self.declarant        = null #Автор заявки, контактные данные
    # self.deliverymode     = null #Способ доставки обращения: спр.№58
    # self.actid	          = null

    yield

    status_reg = self.service_request_statuses.find_by_statusid(440001)
    if status_reg
      status_reg.statusdate = self.regdate
      status_reg.save
    end

    # service_request_equipment
    self.build_service_request_equipment #Создание эфимерной таблицы связки
    self.service_request_equipment.service_request = self
    self.service_request_equipment.invnumber   = self.invnumber
    self.service_request_equipment.equipmentid = self.equipmentid
    self.service_request_equipment.buchetid    = self.equipment.buhuchetid
    self.service_request_equipment.save

    self.build_check1    # Создание проверки
    self.check1.service_request = self # Обратные связи для совместимости с CIA
    self.check1.checkdate       = self.regdate # Дата диагностиического заключения
    self.check1.operatingconditions = 1 #соответствуют требованиям
    self.check1.extdamage = 'отсутствуют'
    self.check1.conclusion = 1
    self.check1.failure_cause = 500008
    self.check1.save

    self.build_executant # Создание выполнения
    self.executant.eqpmntcheckid = self.check1.id # Обратные связи для совместимости с CIA
    self.executant.cablesexist   = self.check1.cablesexist
    self.executant.docexist      = self.check1.docexist
    self.executant.packexist     = self.check1.packexist
    self.executant.extdamage     = self.check1.extdamage
    self.executant.stopperdamage = self.check1.stopperdamage
    self.executant.save
  end

  def save_sub_objects
    if (check_id = (check2 ? check2_id : check1_id))
      executant.eqpmntcheckid = check_id
    end
    check2.save if check2 && check2.changed?
  end
end

class ServiceRequestEquipment < CiaDatabase
  self.table_name = "SERVICEREQUESTEQUIPMENT"
  self.primary_key = 'id'
  self.sequence_name = 'gn_global'
  belongs_to :service_request, foreign_key: 'requestid'
  belongs_to :terminal_equipment, foreign_key: 'equipment'
end

class ServiceRequestStatus < CiaDatabase
  self.table_name = "SERVICEREQUESTSTATUS"
  self.primary_key = 'id'
  self.sequence_name = 'gn_global'
  belongs_to :service_request, foreign_key: 'requestid'
end
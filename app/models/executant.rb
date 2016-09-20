class Executant < CiaDatabase
  self.table_name = "SERVICEREQUESTEXECUTANT"
  self.primary_key = 'id'
  self.sequence_name = 'gn_global'

  has_one :service_request, autosave: false
  #  belongs_to :check, foreign_key: 'eqpmntcheckid'

  include Redmine::SafeAttributes
  safe_attributes 'senddate', 'iswarrantyrepair', 'repairdescription', 'sendto_oadt', 'isiacexecuted',
                  'sendtoservicecentre', 'getdate', 'isdecommission'
  attr_accessible 'senddate', 'iswarrantyrepair', 'repairdescription', 'sendto_oadt', 'isiacexecuted',
                  'sendtoservicecentre', 'getdate', 'isdecommission'

  def iswarrantyrepair_text
    (iswarrantyrepair==0    ? 'не ' : '') + 'гарантийный'
  end
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
  # isdecomission

end
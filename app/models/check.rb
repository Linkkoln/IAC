class Check < CiaDatabase

  self.table_name = "SERVICEREQUESTEQPMNTCHECK"
  self.primary_key = 'id'
  self.sequence_name = 'gn_global'

  include ActiveModel::Dirty

  validate :repair_validate
  around_create    :patch_sub_objects_around_create
  before_save :set_conclusion, :set_failure_cause
  belongs_to :service_request, foreign_key: 'requestid', autosave: false
  has_one    :service_request_as_check1, class_name: "ServiceRequest", foreign_key: 'check1_id', inverse_of: :check1, autosave: false
  has_one    :service_request_as_check2, class_name: "ServiceRequest", foreign_key: 'check2_id', inverse_of: :check2, autosave: false
  has_many   :check_conclusions,    dependent: :destroy, foreign_key: 'eqpmntcheckid', autosave: true #Рекомендация либо в ремонт либо вывод из эксплуатации
  has_many   :check_failure_causes, dependent: :destroy, foreign_key: 'eqpmntcheckid', autosave: true #Будет только одна причина

  # Атавизм. оставлен исключительно для каскадного удаления
  has_one  :executant,            dependent: :destroy, foreign_key: 'eqpmntcheckid'

  include Redmine::SafeAttributes
  safe_attributes 'service_request', 'cablesexist', 'docexist', 'packexist', 'extdamage','stopperdamage','operatingconditions',
                  'problemdscrptn','checkdate','problemdscrptn2'
  attr_accessible  :cablesexist,:docexist,:packexist,:extdamage,:checkdate,:stopperdamage,:operatingconditions,
                   :problemdscrptn,:problemdscrptn2

  def patch_sub_objects_around_create
    # Если создается повторная проверка то
    # копируем данные из первой проверки во вторую
    if self.service_request_as_check2 #self.service_request_as_check2.check2 == self
      check1 = self.service_request_as_check2.check1
      self.cablesexist         = check1.cablesexist
      self.docexist            = check1.docexist
      self.packexist           = check1.packexist
      self.stopperdamage       = check1.stopperdamage
      self.operatingconditions = check1.operatingconditions
      self.problemdscrptn      = check1.problemdscrptn
      self.checkdate           = Date.current
      self.problemdscrptn2     = check1.problemdscrptn2
      self.service_request     = self.service_request_as_check2
    end
    yield
    if self.service_request_as_check2
      self.service_request.executant.eqpmntcheckid = self.id
    end
  end


  ################################################################
  ##           conclusion
  ################################################################
  def conclusions
    {1 => 'передача в ремонт, ввод в эксплуатацию после ремонта',
     2 => 'невозможность восстановительного ремонта, вывод из эксплуатации',
     3 =>  'экономическая нецелесообразность ремонта, вывод из эксплуатации'}
  end

  def conclusion
    unless @conclusion
      eq = check_conclusions.where(conclusionid: 590001..590003).order(:conclusionid)
      @conclusion = eq.count == 1 ? (eq.first.conclusionid - 590000) : nil
    end
    @conclusion
  end

  def conclusion_name
    conclusion.to_i > 0 ? conclusions[conclusion] : ''
  end

  def conclusion= (value)
    attribute_will_change!('conclusion') if conclusion != value
    @conclusion = value ? value.to_i : nil
  end

  def conclusion_changed?
    changed.include?('conclusion')
  end

  def set_conclusion
    self.check_conclusions.clear
    if @conclusion
      self.check_conclusions.new(conclusionid: 590000 + @conclusion)
      self.check_conclusions.new(conclusionid: (@conclusion==1 ? 590004:590005))
    end
  end
  private :set_conclusion

  ################################################################
  ##           failure_cause
  ################################################################

  # Список возможных значений
  def failure_causes
    CatalogContent.where(catalogid: 50).order(:contentid)
  end

  def failure_cause
    unless @failure_cause
      cause = self.check_failure_causes.order(:eqpmntcheckid).first
      @failure_cause = cause ? cause.causeid : nil
    end
    @failure_cause
  end

  def failure_cause_name
    c=CatalogContent.where(contentid: failure_cause).first if failure_cause
    c ? c.name : ''
  end

  def failure_cause= (value)
    attribute_will_change!('failure_cause') if failure_cause != value
    @failure_cause = value ? value.to_i : nil
  end

  def failure_cause_changed?
    changed.include?('failure_cause')
  end

  def set_failure_cause
    self.check_failure_causes.clear
    self.check_failure_causes.new(causeid: @failure_cause) if @failure_cause
  end
  private :set_failure_cause

  def completeness
    ' соединительные кабели' +  (cablesexist==1 ? '; ':' отсутствуют; ') +
        ' документация'+            (docexist==1    ? '; ':' отсутствует; ')+
        ' упаковка производителя' + (docexist==1    ? '; ':' отсутствует; ')
  end

  def stopperdamage_text
    (stopperdamage==0       ? 'не ' : '') + 'повреждены'
  end

  def operatingconditions_text
    (operatingconditions==0 ? 'не ' : '') + 'соответствуют требованиям'
  end

  private

  def repair_validate
    #if checkdate < service_request.regdate
    #  errors.add :checkdate, :greater_than_start_date
    #end
  end
end

class CheckConclusion < CiaDatabase
  self.table_name = "EQUIPMENTCHECKCONCLUSION"
  self.primary_key = 'id'
  self.sequence_name = 'gn_global'
  # default_scope { where("eqpmntcheckid in (590001, 590002, 590003)") }
  attr_accessible :conclusionid
  belongs_to :check, foreign_key: 'eqpmntcheckid'
end

class CheckFailureCause < CiaDatabase
  self.table_name = "EQUIPMENTFAILURECAUSE"
  self.primary_key = 'id'
  self.sequence_name = 'gn_global'
  attr_accessible :causeid
  belongs_to :check, foreign_key: 'eqpmntcheckid'
end



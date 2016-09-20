#!/bin/env ruby
# encoding: utf-8
class Equipment < CiaDatabase
  include Repairs
  self.table_name = "TERMINALEQUIPMENT"
  self.primary_key = 'id'
  self.sequence_name = 'gn_global'
  attr_accessible :stationname, :sernumber, :remark, :ownerequipmentid, :equipmenttype, :place_id, :place_name
  around_create :set_child_by_default
  after_save :update_printer

  has_many   :equipment_request,     inverse_of: :equipment
  has_many   :service_requests,      inverse_of: :equipment, foreign_key: 'equipmentid',      dependent: :destroy
  has_many   :children,              foreign_key: "ownerequipmentid", class_name: "Equipment"

  belongs_to :main,                  foreign_key: "ownerequipmentid", class_name: "Equipment"
  belongs_to :equipment_category,    foreign_key: "equipmenttype"
  belongs_to :institutionaddres,     foreign_key: "bldgaddressid",    class_name: "InstitutionAddress"
  belongs_to :status,                foreign_key: "statusid",         class_name: "EquipmentStatus"
  belongs_to :place

  def related_equipment
    @related_equipment ||= Equipment.where("ownerequipmentid=#{id}"+ (ownerequipmentid ? " or id=#{ownerequipmentid}" : '')).preload(:service_requests, :status).all
  end

  def related_children
    @related_children ||= related_equipment.find_all{|eq| eq.ownerequipmentid == id}
  end

  def related_owner
    @related_owner ||= related_equipment.find_all{|eq| eq.id == ownerequipmentid}
  end

  def related(type)
    related_children.find{|eq| eq.equipmenttype== EquipmentCategory[type]}
  end

  def related_monitor() @monitor||=related(:monitor); end
  def related_printer() @printer||=related(:printer); end
  def related_ibp()     @ibp    ||=related(:ibp);     end
  def has_ibp?()     !!related_ibp;      end
  def has_monitor?() !!related_monitor;  end
  def has_printer?() !!related_printer;  end

  def type_name
    @type_name||=equipment_category.name
  end

  def is_type_of?(type) equipmenttype==EquipmentCategory[type]; end
  def is_arm?() is_type_of?(:arm); end
  def is_printer?() is_type_of?(:printer); end

  def status_repair?
    service_requests.where("rezultid is null or not rezultid in (230001, 230002)").count>0
  end

  def is_warranty_text(to_date)
    (is_warranty?(to_date)  ? '' : 'не ') + 'гарантийный'
  end

  def is_warranty?(to_date)
    (warrantyenddate||(getdate.years_since(3))) > to_date
  end

  def set_child_by_default
    #self.equipmenttype        = EquipmentCategory.get_id(params[:equipment_category])
    main = self.main
    self.getdate       = main.getdate
    self.invnumber     = main.invnumber
    self.statusid      = main.statusid
    self.remark        = main.remark
    self.bldgaddressid = main.bldgaddressid
    self.ownerid       = main.ownerid
    self.setplaceid    = main.setplaceid
    self.isinheritedinvnumber = 0
    yield
  end

  def project_id
    Organization.find_by_oa_id_iac(self.setplaceid).project_id
  end

  def project_id=(project_id)
    self.setplaceid = Organization.find_by_project_id(project_id).oa_id_iac
  end

  def printer_status
    case self.statusid
      when 50001, 50002
        "Исправен"
      when 50003, 50007
        "Неисправен"
      else
        "Списан"
    end
  end

  def set_status_from_issue(issue_status_id)
    case issue_status_id
      when STATUS_NEW,             # Новая
          STATUS_FORMED           # Сформирована
        self.statusid = 50003 # Неисправно: подлежит ремонту
      when STATUS_DIAGN,           # Диагностика
          STATUS_PURCHASE,        # Закупка
          STATUS_SUSPEND          # Приостановлено
        self.statusid = 50007 # Отправлено в ремонт
      when STATUS_COMMISSIONING    # Ввод в эксплуатацию
        self.statusid = 50001 # С клад (Рабочее)
      when STATUS_CLOSE            # Закрыто
        self.statusid = 50002 # Установлено
      when STATUS_WRITE_OFF,       # На списание
          STATUS_WRITE_OFF_USD    # Списание УСД
        self.statusid = 50004 # Склад (Неисправно: подлежит списанию)
      when STATUS_WRITTEN_OFF      # Списано
        self.statusid = 50005 # Склад (Списано)
    end
  end

  serialize :remark, Hash
  def place_id()
    begin
      remark[:id]
    rescue
      nil
    end
  end
  def place_name()
    begin
      remark[:name]
    rescue
      remark
    end
  end
  def place_id=(v)
    v=v.to_i
    self.remark = v>0 ? {id: v, name: Place.find(v).full_name} : nil
  end
  def place_name=(v) remark[:name] = v; end

  private

  #Full texts 	id 	project_id 	printer_category_id 	court 	court_vin 	brand 	model 	inventory 	serial 	cartridge 	commissioning  	status 	place 	person

  def update_printer
    if self.is_printer?
      if (printer = Printer.find_or_create_by(id: id))
        printer.project_id = self.project_id
        printer.inventory = self.invnumber
        printer.serial = self.sernumber
        printer.commissioning = self.getdate
        printer.status = self.printer_status


         #   stationname, :sernumber, :remark, :ownerequipmentid, :equipmenttype
        #(project_id, printer_category_id, inventory, serial, commissioning, status, place, person)
      end
    end
  end
end
class Printer < ActiveRecord::Base
  unloadable

  attr_accessible :inventory, :serial, :commissioning, :status, :place, :printer_category_id

  belongs_to :project
  belongs_to :printer_category
  has_many :printers_issues

  include Redmine::SafeAttributes

  safe_attributes  'court',
      'court_vin',
      'brand', 'model', 'inventory',
      'serial', 'cartridge', 'commissioning',
      'status', 'place', 'person', 'printer_category_id'

  scope :worked, lambda{where(status: "Исправен")}

  def equipment
    Equipment.find(id)
  end

  def name
    printer_category.name
  end

  def cartridge_category
    printer_category.cartridge
  end

  def self.create_or_modify(equipment)
    unless Printer.exists?(equipment.id)
      if (printer_category = PrinterCategory.where("concat('Принтер ',brand,' ',model) = ?", equipment.stationname).first) &&
         (organization = Organization.find_by_oa_id_iac(equipment.setplaceid))

        printer = Printer.new
        printer.id                  = equipment.id
        printer.inventory           = equipment.invnumber
        printer.serial              = equipment.sernumber
        printer.place               = equipment.place_name
        printer.commissioning       = equipment.getdate
        printer.printer_category_id = printer_category.id
        printer.brand               = printer_category.brand
        printer.model               = printer_category.model
        printer.court               = organization.name
        printer.court_vin           = organization.code
        printer.project_id          = organization.project_id
        printer.status              = case equipment.statusid
                                        when 50002
                                          'Исправен'
                                        when 50003, 50007
                                          'Неисправен'
                                        when 50004, 50005, 50006
                                          'Списан'
                                      end
        printer.save
      end
    end
  end
end

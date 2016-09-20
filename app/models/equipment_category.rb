EQUIPMENT_TYPE = {arm: 10002, printer: 10004, ibp: 10014, monitor: 10010}
class EquipmentCategory < CiaDatabase
  self.table_name = "CATALOGCONTENT"
  self.primary_key = "contentid"
  default_scope { where(catalogid: 1)}
  belongs_to :equipment_category_group, foreign_key: 'group_id'

  scope :sorted, lambda { order(:name) }

  # def self.all
  #   @@equipment_categories ||= EquipmentCategory.all
  # end

  def self.[](type)
    EQUIPMENT_TYPE[type.to_sym]
  end

  def self.get_id(type)
    self[type]
  end

  # def self.get_id(c)
  #   case c
  #     when 'ibp'       then 10014
  #     when 'arm'       then 10002
  #     when 'monitor'   then 10010
  #     when 'printer'   then 10004
  #     else nil
  #   end
  # end
end
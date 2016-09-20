class EquipmentStatus < CiaDatabase
  self.table_name = "CATALOGCONTENT"
  self.primary_key = "contentid"
  default_scope { where(catalogid: 5)}
end
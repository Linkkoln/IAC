class EquipmentCategoryGroup < ActiveRecord::Base
  unloadable
  has_many :equipment_categories, foreign_key: 'group_id', dependent: :nullify
  accepts_nested_attributes_for :equipment_categories
  attr_accessible  :name, :ord
end

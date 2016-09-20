class CreateEquipmentCategoryGroups < ActiveRecord::Migration
  def change
    create_table :equipment_category_groups do |t|
      t.string :name
      t.integer :ord
    end
    add_index :equipment_category_groups, :ord
  end
end

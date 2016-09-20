class CreateEquipmentRequests < ActiveRecord::Migration
  def change
    create_table :equipment_requests do |t|
      t.belongs_to :issue, index: true, foreign_key: true
      t.belongs_to :equipment, index: true
      t.belongs_to :request, index: true
    end
  end
end

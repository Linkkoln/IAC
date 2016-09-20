class CreateFloors < ActiveRecord::Migration
  def change
    create_table :floors do |t|
      t.integer :building_id
      t.string :name
      t.binary :plan, :limit => 10.megabyte
      t.integer :ord
    end
    add_index :floors, :building_id
    add_index :floors, :ord
  end
end

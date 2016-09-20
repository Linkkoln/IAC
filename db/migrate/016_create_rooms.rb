class CreateRooms < ActiveRecord::Migration
  def change
    create_table :rooms do |t|
      t.integer :floor_id
      t.string :name
      t.integer :category
      t.string :area
      t.integer :ord
    end
    add_index :rooms, :floor_id
    add_index :rooms, :ord
  end
end

class CreatePlaces < ActiveRecord::Migration
  def change
    create_table :places do |t|
      t.integer :floor_id
      t.string :name
      t.integer :category
      t.string :point
      t.integer :ord
    end
    add_index :places, :floor_id
    add_index :places, :ord
  end
end

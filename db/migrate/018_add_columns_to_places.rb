class AddColumnsToPlaces < ActiveRecord::Migration
  def change
    add_column :places, :room_id,             :integer
    add_column :places, :work_place_category, :integer
    add_index :places, :room_id
  end
end

# t.integer :room_id
# t.integer :work_place_category
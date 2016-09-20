class AddColumnsToFloors < ActiveRecord::Migration
  def change
    add_column :floors, :viewbox,    :string
    add_column :floors, :polygon,    :string
    add_column :floors, :primitives, :string, limit: 10000
  end
end

# t.integer :room_id
# t.integer :work_place_category
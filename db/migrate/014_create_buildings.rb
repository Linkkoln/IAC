class CreateBuildings < ActiveRecord::Migration
  def change
    create_table :buildings do |t|
      t.integer :organization_id
      t.string :post_index
      t.string :locality_place
      t.string :street
      t.string :num
      t.integer :ordinal
      t.integer :institution_address_id
    end
  end
end

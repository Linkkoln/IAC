class CreateRoleTrackers < ActiveRecord::Migration
  def change
    create_table :role_trackers do |t|
      t.integer :role_id
      t.integer :tracker_id
    end
  end
end

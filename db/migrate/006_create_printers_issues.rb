class CreatePrintersIssues < ActiveRecord::Migration
  def up
    create_table :printers_issues do |t|
      t.integer :printer_id
      t.integer :issue_id
      t.integer :tracker_id #Включен в issue, т.е. смысл этого поля не большой
      t.integer :crtr_plan
      t.integer :crtr_real
      t.integer :crtr_send
      t.integer :crtr_filled
      t.integer :crtr_restored
      t.integer :crtr_killed
      t.integer :crtr_new
    end
    add_index :printers_issues, [:issue_id, :printer_id], unique: true
  end

  def down
    drop_table :printers_issues
  end
end

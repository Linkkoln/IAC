class AddActiveToPrinterCategory < ActiveRecord::Migration
  def change
    add_column :printer_categories, :active, :integer, default: 1
  end
end

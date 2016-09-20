class CreatePrinterCategories < ActiveRecord::Migration
  def up
    create_table :printer_categories do |t|
      t.string :brand
      t.string :model
      t.string :cartridge
    end
    add_index :printer_categories, [:brand, :model], unique: true

    # Загоняем дянные из csv
    file_name = Dir.pwd + '/plugins/iac/db/printer_category.csv'
    csv_text = File.read(file_name)
    csv = CSV.parse(csv_text, :headers => true, :col_sep => ";")
    csv.each do |row|
      PrinterCategory.create!(row.to_hash,{:without_protection => true})
    end
  end

  def down
    drop_table :printer_categories
  end
end

require 'csv'
class CreatePrinters < ActiveRecord::Migration
  def up
    create_table :printers do |t|
      t.integer :project_id
      t.integer :printer_category_id
      t.string  :court
      t.string  :court_vin
      t.string  :brand
      t.string  :model
      t.string  :inventory
      t.string  :serial
      t.string  :cartridge
      t.date    :commissioning
      t.string  :status
      t.string  :place
      t.string  :person
    end

    #Формируем хаш {Код ОА => project_id}
    @cast_field_code_oa = CustomField.find_by_name('Код ОА')
    @projects = Project.joins(:custom_values).
        where("custom_values.value IS NOT NULL AND custom_values.custom_field_id = #{@cast_field_code_oa.id}").
        order("projects.name").all
    @pr = {}
    @projects.each { |item| @pr.merge! item.custom_value_for(@cast_field_code_oa).to_s => item.id }

    # Загоняем дянные из csv
    file_name = Dir.pwd + '/plugins/iac/db/printers.csv'
    csv_text = File.read(file_name)
    csv = CSV.parse(csv_text, :headers => true, :col_sep => ";")
    csv.each do |row|
      rh = row.to_hash
      rh['project_id'] = @pr[rh['court_vin']].to_i
      if t = PrinterCategory.find_by(brand: rh['brand'], model: rh['model'])
        rh['printer_category_id'] = t.id
      end
      Printer.create!(rh,{:without_protection => true})
    end
  end

  def down
    drop_table :printers
  end
end

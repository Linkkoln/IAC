class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :name      #Наименование
      t.string :code      #Код
      t.text :address   #Юридический адрес
      t.string :telefone  #Телефон
      t.integer :organization_category_id #Категория Организации
      t.integer :engineer_id              #Ответственный инженер User
      t.string :employee_fio
      t.string :employee_position
      t.integer :responsible_person_id    #Мат.ответственное лицо Employee
      t.timestamps null: false
    end
  end
end

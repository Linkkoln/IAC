class CreateOrganizationCategories < ActiveRecord::Migration
  def up
    create_table :organization_categories do |t|
      t.string :org_name
    end
    OrganizationCategory.create(
        [{id: 1, org_name: 'ВС'},
         {id: 2, org_name: 'СД'},
         {id: 3, org_name: 'ИАЦ'},
         {id: 4, org_name: 'Филиал ИАЦ'},
         {id: 5, org_name: 'Суд региона'},
         {id: 6, org_name: 'УСД'},
         {id: 7, org_name: 'Районный суд'},
         {id: 8, org_name: 'Мировой суд'},
         {id: 9, org_name: 'Окружной суд'},
         {id: 10, org_name: 'Гарнизонный суд'},
         {id: 11, org_name: 'ФАС'},
         {id: 12, org_name: 'ААС'},
         {id: 13, org_name: 'АС'}],
        {:without_protection => true})
    #TODO Выяснить почему так не работает
    #OrganizationCategory.create({id: 15, org_name: 'asdf'}, :without_protection => true)
    # Выяснил. В редмайне имеется собственная защита, которая пока хз как работает
  end

  def down
    drop_table :organization_categories
  end
end
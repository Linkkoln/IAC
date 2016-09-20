class CreateOrders < ActiveRecord::Migration
  def up
    create_table :orders do |t|
      t.date :starting_date
      t.string :num
    end
    Order.create(
        [{id: 1, starting_date: '20.11.2013', num:'num'},
         {id: 2, starting_date: '24.02.2014', num:'1-02/19'},
         {id: 3, starting_date: '15.05.2014', num:'1-02/63'},
         {id: 4, starting_date: '20.02.2015', num:'1-02/26'},
         {id: 5, starting_date: '20.07.2015', num:'1-02/124'}],
        {:without_protection => true})
    #TODO Выяснить почему так не работает
    #OrganizationCategory.create({id: 15, org_name: 'asdf'}, :without_protection => true)
    # Выяснил. В редмайне имеется собственная защита, которая пока хз как работает
  end

  def down
    drop_table :organization_categories
  end

end

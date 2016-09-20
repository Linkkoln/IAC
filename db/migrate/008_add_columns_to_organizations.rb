class AddColumnsToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :oa_id_iac, :integer
    add_column :organizations, :court_category_id_iac, :integer
    add_column :organizations, :oa_id_usd, :integer
    add_column :organizations, :project_id, :integer
    add_index :organizations, :code
    add_index :organizations, :organization_category_id
    add_index :organizations, :oa_id_iac
    add_index :organizations, :court_category_id_iac
    add_index :organizations, :oa_id_usd
    add_index :organizations, :project_id
  end
end

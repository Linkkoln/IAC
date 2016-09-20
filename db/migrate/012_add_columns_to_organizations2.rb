class AddColumnsToOrganizations2 < ActiveRecord::Migration
  def change
    add_column :organizations, :phone_code,    :string
    add_column :organizations, :district_name, :string
    add_column :organizations, :name_r,        :string
    add_column :organizations, :head_name,     :string
    add_column :organizations, :head_name_r,   :string
    add_column :organizations, :head_short_name,   :string
    add_column :organizations, :head_short_name_r, :string
    add_column :organizations, :count_of_judges,   :integer
    add_column :organizations, :full_time_staff,   :integer
  end
end
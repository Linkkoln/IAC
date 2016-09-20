module OrganizationsHelper
  include IacHelper

  def organization_tabs
    [{:name => 'basic',      :partial => 'organizations/basic',      label: :label_menu_basic},
     {:name => 'equipments', :partial => 'organizations/equipments', label: :label_menu_equipments},
     {:name => 'users',      :partial => 'organizations/users',      label: :label_menu_users},
     {:name => 'points',     :partial => 'organizations/points',     label: :label_menu_points }]
  end

end

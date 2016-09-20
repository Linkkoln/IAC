class OrganizationCategory < ActiveRecord::Base
  unloadable # Нафига - не понятно, но пока оставим

  # Условности, которые надо соблюдать в редмайне, для защиты бд
  #     attr_accessible :name
  #     attr_accessible :name, :is_admin, :as => :admin

  has_many :organizations
end

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'multiply_issue/:id', :to => 'co#multiply'

# Роуты к шаблонам описывать тут
get 'templates/report_co3/:type/:year/:num', to: 'templates#report_co3'
get 'projects/:project/co6/:num', to: 'templates#make_act_co6'

get 'repairs/list_svod', to: 'repairs#list_svod'

#resources :organizations

resources :issues do
  member do
    get 'repairs/:file', to: 'repairs#make_file'
    get 'cartridges/:file', to: 'templates#make_file_for_cartridges'
    get 'receive_cartridges', to: 'cartridges#receive_to_tank'
  end
end

resources :projects do
  member do
    get 'act_co3/:year/:month', to: 'templates#make_act_co3'
    #get 'projects/act_co3/:project/:mon/:file', to: 'templates#make_act_co3'
  end
  resources :printers
  resources :equipments do
    member do
      get 'select'
      get 'new_repair'
    end
  end
end

#get 'delete_repair/:equipment_request_id'
#get 'equipments/import' , :to => 'equipments#import'



get 'projects/:project_id/printers' , :to => 'printers#index'
get 'printers/:project_id/context_menu' , :to => 'printers#context_menu'

post 'printers/:project/cartridge' , :to => 'printers#cartridge'
get 'printers/import', :to => 'printers#import'
get 'printers/export', :to => 'printers#export'
get 'printers/upload', :to => 'printers#upload'

get  'issues/:id/cartridge_category/:cartridge', :to => 'cartridges#edit'
post 'issues/:id/cartridge_category/:cartridge', :to => 'cartridges#update'

post 'role_trackers/reload', :to => 'role_trackers#reload'
resources :role_trackers
resources :organizations do
  collection do
    get 'import'
    get 'synchronize'
  end
end
resources :floors do
  resources :places
  resources :rooms do
    collection do
      get 'quick_new'
      post 'quick_create'
    end
  end
  member do
    get 'plan'
  end

end
resources :places
#get 'organizations/import', :to => 'organizations#import'

resources :printer_categories
resources :equipment_category_groups
resources :equipments
get 'equipments/delete_repair/:id/:project_id/:service_request_id' , :to => 'equipments#delete_repair'
get 'equipment/:equipment/link_to_issue/:issue', :to => 'equipments#set_link_to_issue'
#get 'equipment/destroy_link_from_issue/:issue', :to => 'equipments#destroy_link_from_issue'
get 'issues_without_link', :to => 'equipments#issues_without_link'
get 'synchronize', to: 'repairs#synchronize'
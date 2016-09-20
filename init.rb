#!/bin/env ruby
# encoding: utf-8

require_dependency 'iac_hook'
require 'controller_issues_new_before_save_hook'
require 'controller_issues_edit_after_save_hook'
require 'controller_issues_edit_before_save_hook'
require 'controller_issues_bulk_edit_before_save_hook'
require 'string_patch'
require 'calendar'

Date::DATE_FORMATS[:default] = "%d.%m.%Y"
Time::DATE_FORMATS[:default] = "%d.%m.%Y %H:%M"

Redmine::Plugin.register :iac do
  name "ФГБУ ИАЦ"
  author 'Mahanov Valeriy'
  description "Плагин ФГБУ ИАЦ для Redmine"
  version '0.1.3'
  url ''
  author_url ''


#  menu :top_menu, :organizations,
#       {:controller => 'organizations', :action => 'index'},
#       :caption => 'Организации'

  project_module :printers do
    permission :printers_view, :printers => :index
    permission :cartridge_process_application, {printers: [:index, :edit, :update, :context_menu, :cartridge],
                                                             cartridges: [:edit, :update]}
    permission :cartridge_make_application, {printers: [:index, :edit, :update, :context_menu, :cartridge]}
    permission :printer_categories_edit, printer_categories: [:index, :show, :edit, :update, :new, :create, :delete], :require => :loggedin
    permission :tanker, cartridges: [:receive_to_tank], :require => :loggedin
  end

  project_module :equipments do
    permission :organizations, organizations: [:index, :show, :edit, :update], :require => :loggedin
    permission :equipments_view,    equipments: [:index, :show]
    permission :equipments_edit,    equipments: [:index, :show, :edit, :update, :new, :create]
    permission :equipments_manage,  equipments: [:index, :show, :edit, :update, :new, :create, :delete]
    permission :repair_request_new, equipments: [:request_new]
    permission :repairs_start_edit, issue: [:edit]
    permission :repairs_exec_edit,  issue: [:edit]
    permission :repairs_manager,    issue: [:edit]
    permission :repair_link_to_request, :equipments => :set_link_to_issue
  end

  # project_module :organizations do
  #
  # end

  settings :default => {'empty' => true}, :partial => 'settings/iac'


  # Пример как люди меню организовали
  # # adding the patch
  #       require 'menu_patch'
  #   Redmine::MenuManager::MenuHelper.send(:include, MenuPatch)
  #
  #
  # # setup an menu entry into the redmine top-menu on the upper left corner
  #       menu :top_menu, :time_tracker_main_menu, {:controller => 'time_trackers', :action => 'index'}, :caption => :time_tracker_label_main_menu, :if => Proc.new { User.current.logged? }
  #
  # # create the plugin-specific menu
  #   Redmine::MenuManager.map :timetracker_menu do |menu|
  #     menu.push :time_tracker_menu_tab_overview, {:controller => 'time_trackers', :action => 'index'}, :caption => :time_tracker_label_menu_tab_overview, :if => Proc.new { User.current.logged? }
  #     menu.push :time_tracker_menu_tab_logs, {:controller => 'time_logs', :action => 'index'}, :caption => :time_tracker_label_menu_tab_logs, :if => Proc.new { User.current.logged? }
  #   end


  # menu :top_menu, :time_tracker_main_menu, {:controller => 'equipments', :action => 'index'}, :caption => "ИАЦ", :if => Proc.new { User.current.logged? }
  # Redmine::MenuManager.map :timetracker_menu do |menu|
  #   menu.push :time_tracker_menu_tab_overview, {:controller => 'equipments', :action => 'index'}, :caption => :time_tracker_label_menu_tab_overview, :if => Proc.new { User.current.logged? }
  #   menu.push :time_tracker_menu_tab_logs, {:controller => 'organizations', :action => 'index'}, :caption => :time_tracker_label_menu_tab_logs, :if => Proc.new { User.current.logged? }
  # end


  menu :application_menu, :equipments,          { :controller => 'equipments',          :action => 'index'}, :caption => 'Оборудование',
         if: Proc.new {User.current.allowed_to?({ :controller => 'equipments',          :action => 'index'}, nil, global: true)}
  menu :application_menu, :organizations,       { :controller => 'organizations',       :action => 'index'}, :caption => 'Объекты автоматизации',
         if: Proc.new {User.current.allowed_to?({ :controller => 'organizations',       :action => 'index'}, nil, global: true)}
  menu :application_menu, :printer_categories,  { :controller => 'printer_categories',  :action => 'index'}, :caption => 'Категории принтеров',
         if: Proc.new {User.current.allowed_to?({ :controller => 'printer_categories',  :action => 'index'}, nil, global: true)}

 # permission :printers, { :printers => [:index] }, :public => true
  menu :project_menu, :printers,   {:controller => 'printers',   :action => 'index'}, :caption => 'Принтеры',     :param => :project_id, after: :new
  menu :project_menu, :equipments, {:controller => 'equipments', :action => 'index'}, :caption => 'Оборудование', :param => :project_id, after: :new


  menu :admin_menu, :iac, {:controller => 'settings', :action => 'plugin', :id => "iac"}, :caption => :iac_title

  # menu :top_menu, :repair,     '/projects/fgbw/issues?query_id=65', :caption => "Ремонты"
  # menu :top_menu, :repair_65,  '/projects/fgbw/issues?query_id=65', :caption => "В сервисном центре"
  # menu :top_menu, :repair_67,  '/projects/fgbw/issues?query_id=67', :caption => "На выдачу"
  # menu :top_menu, :repair_23,  '/projects/fgbw/issues?query_id=23', :caption => "Введены в эксплуатацию, но не закрыты"
  # menu :top_menu, :repair_05,  '/projects/fgbw/issues?query_id=5',  :caption => "Без первичных документов"
  # menu :top_menu, :repair_39,  '/projects/fgbw/issues?query_id=39', :caption => "Без итоговых документов"


  #Rails.configuration.to_prepare do
  #  Project.send(:include, RedmineProjectPriority::ProjectPatch)
  #  ProjectsController.send(:include, RedmineProjectPriority::ProjectsControllerPatch)

  #  Issue.send(:include, RedmineProjectPriority::IssuePatch)
  #  IssueQuery.send(:include, RedmineProjectPriority::IssueQueryPatch)

  #  Query.send(:include, RedmineProjectPriority::QueryPatch)
  #end

end

ActionDispatch::Callbacks.to_prepare do
  require_dependency 'issue_patch'
  require_dependency 'project_patch'
  #require_dependency 'issue_query_patch'
end

unless IssuesHelper.included_modules.include? EquipmentsHelper
  IssuesHelper.send(:include, EquipmentsHelper::Common)
end
#!/bin/env ruby
# encoding: utf-8
module Iac


  class ControllerIssuesBulkEditBeforeSaveHook < Redmine::Hook::ViewListener

    include Repairs
    include Cartridges

    def controller_issues_bulk_edit_before_save(context={})

      #Блок Копирования проверяющего в автора для реализации
      context[:issue].author_id = context[:issue].inspector.value if context[:issue].inspector && !context[:issue].inspector.blank?

      case context[:issue].tracker.name
        when 'Картриджи' #Раздел обработки задач с трекером 'Картриджи'
          cartridge_updete context
        when 'Ремонт'
          repair_update(context) if context[:issue].can_repair_start_edit?()
      end
    end
  end
end
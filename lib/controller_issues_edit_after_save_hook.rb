#!/bin/env ruby
# encoding: utf-8
module Iac
  class ControllerIssuesEditAfterSaveHook < Redmine::Hook::ViewListener

    include Repairs

    def controller_issues_edit_after_save(context={})

      case context[:issue].tracker.name
        when 'Картриджи'
          context[:issue].descendants.each {|i|
            if i.status.name != STATUS_CLOSE
              i.status = context[:issue].status
              i.save
            end
          } if context[:params][:update_descendants_status]
        when 'Ремонт'
          #repair_save context
      end
    end
  end
end
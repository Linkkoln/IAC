#!/bin/env ruby
# encoding: utf-8

module Iac
  class ControllerIssuesNewBeforeSaveHook < Redmine::Hook::ViewListener

    def controller_issues_new_before_save(context={})
      cast_checker_id = CustomField.find_by_name('Проверяющий').id.to_s
      if context[:params] && context[:params][:issues]
        if (context[:params][:issues][:custom_field_values][cast_checker_id].to_s != '')
          context[:issues].author_id = context[:params][:issues][:custom_field_values][cast_checker_id].to_i
        end
      end
    end
  end
end
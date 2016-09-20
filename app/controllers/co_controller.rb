#!/bin/env ruby
# encoding: utf-8
class CoController < ApplicationController
  @@mult_issue = []

  def multiply
    @cur_issue = Issue.find(params[:id])
    #TODO Блок проверяющий не выполняется ли аналогичная задача в другом инстансе

    unless @@mult_issue.include?(@cur_issue.id)

      @c = @@mult_issue = @@mult_issue + [@cur_issue.id]

      render inline: "<%= @c.to_s %>", layout: false
      @cast_field_code_oa = CustomField.find_by_name('Код ОА')
      @cast_field_request = CustomField.find_by_name('Текст заявки')
      @cast_field_checker = CustomField.find_by_name('Проверяющий')
      @cast_field_number  = CustomField.find_by_name('Номер производства')
      @child_tracker = Tracker.find_by_name(@cur_issue.cf_by_name('Вид работ'))
      # Выполнить проверку прав пользователя

      if ((@cur_issue.assigned_to == User.current) or (User.current.id == 1)) and
          @child_tracker and
          @cur_issue.cf_by_name('Вид работ') != ''
        multiply_issue('23RS')
        multiply_issue('61GV')
      end
      @@mult_issue = @@mult_issue - [@cur_issue.id]
      #redirect_to issue_path(@cur_issue)
    else
      render @@mult_issue
    end
  end

protected

  def multiply_issue(court)
    Project.visible
             .joins(:custom_values)
             .where("custom_values.value LIKE '#{court}%' AND custom_values.custom_field_id = #{@cast_field_code_oa.id}")
             .order("projects.name").all
    .map{|project|
      begin
        #Ищем вложенную задачу в проекте, если задачи нет, то вызывается исключение
        child_issue = Issue.where(:parent_id => @cur_issue.id, :project_id => project.id).first!
      rescue
        #Вложенной задачи нет, поэтому создаем новую
        child_issue = Issue.new
        child_issue.project         = project
        child_issue.assigned_to_id  = project.cf_by_name('Ответственный инженер')
        child_issue.subject         = @cur_issue.subject
        child_issue.author          = @cur_issue.assigned_to
        child_issue.parent_issue_id = @cur_issue.id
        child_issue.start_date      = @cur_issue.start_date
        child_issue.tracker         = @child_tracker
        child_issue.status_id       = 1 #Новая
        child_issue.custom_field_values = {@cast_field_request.id.to_s => @cur_issue.custom_value_for(@cast_field_request).value,
                                           @cast_field_checker.id.to_s => @cur_issue.assigned_to.id.to_s
                                          }
        child_issue.save!
      end
    }
  end


end
#!/bin/env ruby
# encoding: utf-8
require_dependency 'issue'
require_dependency 'equipment_request'
require_dependency 'equipment'
require_dependency 'issue_repairs'

IssueQuery.available_columns << QueryColumn.new(:equipment_category)
IssueQuery.available_columns << QueryColumn.new(:repair_num)
IssueQuery.available_columns << QueryColumn.new(:invnumber)
IssueQuery.available_columns << QueryColumn.new(:sernumber)

module Iac
  module Patches
    module IssuePatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          #default_scope {preload(equipment_request: [equipment: :equipment_category])}
          def self.default_scope
            # В списке задач - реально ускоряет вывод ремонтов, а вот при выводе связанных задач по ремонтам,
            # вызывается для каждой задачи и реально тормозит
            # preload(equipment_request: [:service_request, equipment: :equipment_category])
          end
          # has_and_belongs_to_many :contacts, :uniq => true
          delegate :oa_id_iac, to: :project

          has_one :equipment_request, autosave: true, inverse_of: :issue, dependent: :destroy
          delegate :service_request, to: :equipment_request
          delegate :oa_name, :oa_code, to: :project

          safe_attributes 'service_request'

          validate :due_date_in_future
          validate :repair_validate
          after_save :repair_after_save

          protected
          def due_date_in_future
            return true if due_date.nil?
            if due_date.to_time > Date.today.beginning_of_day+2
              errors.add :due_date, :not_in_future
            end
          end
        end
      end

      module InstanceMethods
        TRACKER_NAME = {3 => 'Восстановление работоспособности',
                        6 => 'Ремонт',
                        11 => 'Настройка и администрирование',
                        12 => 'Внеплановое обновление'}

        include Repairs
        include Iac::IssueRepairs

        def cf_by_name(custom_field_name)
          #custom_value_for(CustomField.find_by_name fname).to_s
          custom_field_by_name(custom_field_name).to_s
        end

        def custom_field_by_name(custom_field_name)
          custom_field_id = CustomField.find_by_name(custom_field_name).id
          custom_field_values.select{|item| item.custom_field_id == custom_field_id}.shift
        end

        def zdate
          t = (due_date-1)
          t.strftime("%d.%m.%Y").to_s
        end

        def ztext() custom_field_by_name("Текст заявки").to_s; end

        def inspector
          custom_field_by_name('Проверяющий')
        end

        def inspector= (c)
          self.inspector.value = c
          #self.custom_field_values = {CustomField.find_by_name('Проверяющий').id.to_s => c}
          self.author_id = c
        end


        def issue_date
          t=due_date
          t.strftime("%d.%m.%Y").to_s
        end

        def full_tracker_name
          TRACKER_NAME[tracker_id]
        end

        def common?
          project.identifier == 'all'
        end

        # Суммы всех картриджей в задаче
        def count_cartridges
          if common?
            ids = []
            descendants.each {|i| ids<<i.id}
          else
            ids = id
          end
          PrintersIssue
              .select('sum(printers_issues.crtr_plan) as plan_count,'+
                          ' sum(printers_issues.crtr_real)     as real_count,'+
                          ' sum(printers_issues.crtr_send)     as send_count,'+
                          ' sum(printers_issues.crtr_filled)   as filled_count,'+
                          ' sum(printers_issues.crtr_restored) as restored_count,'+
                          ' sum(printers_issues.crtr_killed)   as killed_count')
              .joins(printer: :printer_category)
              .where(printers_issues: {issue_id: ids})
              .first
        end

        # Суммы картриджей в задаче по типам
        def cartridges_by_type
          if common?
            ids = []
            descendants.each {|i| ids<<i.id}
          else
            ids = id
          end
          PrintersIssue
            .select('printer_categories.cartridge as cartridge,'+
                        'printer_categories.brand as c_brand,'+
                        ' sum(printers_issues.crtr_plan)     as plan_count,'+
                        ' sum(printers_issues.crtr_real)     as real_count,'+
                        ' sum(printers_issues.crtr_send)     as send_count,'+
                        ' sum(printers_issues.crtr_filled)   as filled_count,'+
                        ' sum(printers_issues.crtr_restored) as restored_count,'+
                        ' sum(printers_issues.crtr_killed)   as killed_count')
            .joins(printer: :printer_category)
            .where(printers_issues: {issue_id: ids})
            .group('c_brand, cartridge')
        end

        def tracker_for_user?(tracker_id)
          RoleTrackers.where(tracker_id: tracker_id, role_id: User.current.roles_for_project(project)).exists?
        end

        def status_cartridge_order
          if tracker.name == 'Картриджи'
            t=case status.name
            when 'Новая'        then  1
            when 'Сформирована' then  2
            when 'Принята'      then  3
            when 'В работе'     then  4
            when 'На выдачу'    then  5
            when 'Закрыта'      then  6
            else                      nil
            end
          else
            nil
          end
          t
        end
        
        def cartridges
          if project.identifier == 'all'
            ids = []
            descendants.each {|i| ids<<i.id}
          else
            ids = id
          end
          PrintersIssue.where(issue_id: ids)
        end
      end
    end
  end
end

unless Issue.included_modules.include?(Iac::Patches::IssuePatch)
  Issue.send(:include, Iac::Patches::IssuePatch)
end




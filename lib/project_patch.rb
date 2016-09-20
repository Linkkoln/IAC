#!/bin/env ruby
# encoding: utf-8
require_dependency 'issue'
require_dependency 'organization'

module Iac
  module Patches
    module ProjectPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          # has_and_belongs_to_many :contacts, :uniq => true
          has_one :organization
          delegate :oa_id_iac, :places_for_select, to: :organization
        end
      end

      module InstanceMethods

        def cf_by_name fname
          @@cf ||= {}
          @@cf[id] ||= {}
          @@cf[id][fname] ||= custom_value_for(CustomField.find_by_name fname).to_s
        end

        def oa_name
          cf_by_name("Наименование ОА")
        end

        def oa_code
          cf_by_name("Код ОА")
        end

        def oa_user
          cf_by_name('Ответственный инженер')
        end

        def system_code
          case cf_by_name("Код ОА")[2..3]
            when "RS"
              "081"
            when "GV"
              "083"
            when "UD"
              "079"
            when "OS"
              "080"
          end
        end

      end
    end
  end
end

unless Project.included_modules.include?(Iac::Patches::ProjectPatch)
  Project.send(:include, Iac::Patches::ProjectPatch)
end




require 'redmine'

module Iac
  module Patches
    module IssueQueryPatch
      def self.included(base) # :nodoc:
        def initialize_available_filters_with_iac_filter
          retval = initialize_available_filters_without_iac_filter
          add_available_filter(
              "equipment_category_id",
              :type => :list_optional,
              :values => EquipmentCategory.sorted.collect{|s| [s.name, s.id.to_s] },
              :label => :label_equipment_category) unless EquipmentCategory.all.empty?
          retval
        end


        base.class_eval do
          alias_method_chain :initialize_available_filters, :iac_filter

          # inherit from IssueQuery, just add project priority
          #self.available_columns << QueryAssociationColumn.new(:equipment_category_id,
          #                                                     :association => :issue,
          #                                                     :field => :equipment_category_id,
          #                                                     :sortable => "#{EquipmentCategory.table_name}.name",
          #                                                     :default_order => 'desc',
          #                                                     :groupable => true,
          #                                                     :caption => :label_equipment_category)
        end
      end
    end
  end
end

unless IssueQuery.included_modules.include?(Iac::Patches::IssueQueryPatch)
  IssueQuery.send(:include, Iac::Patches::IssueQueryPatch)
end
module EquipmentsHelper

  include IssuesHelper


  def filter_field(field)
    field_lebel = ("field_"+field.to_s).to_sym
    s = ''
    s << label_tag(field, l(field_lebel)) << " "
    case field
      when :organization
        s << select(:filter, :organization, options_from_collection_for_select(Organization.all, 'project_id',  'name', @f[field].to_s), include_blank: true)
      else
        s << text_field(:filter, field, value: @f[field].to_s)
    end
    s.html_safe
  end

  module Common
    def select_project_equipment_path(pr, eq, h)
      project_equipment_path(pr,eq) +"/select?equipment_category=#{h.key(:equipment_category).to_s}"
    end

    def my_equipments_path
      if @project
        project_equipments_path
      else
        equipments_path
      end
    end

    def my_equipment_path(project, equipment)
      if project
        project_equipment_path(project, equipment)
      else
        equipment_path(equipment)
      end
    end

    def my_edit_equipment_path(project, equipment)
      if project
        edit_project_equipment_path(project, equipment)
      else
        edit_equipment_path(equipment)
      end
    end

    def my_new_equipment_path (project, main_equipment, equipment_category=nil)
      if project
        new_project_equipment_path(project, main_equipment, equipment_category)
      else
        new_equipment_path(main_equipment, equipment_category)
      end
    end
  end

  include EquipmentsHelper::Common

end
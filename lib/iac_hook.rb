class IacHook < Redmine::Hook::ViewListener
  render_on :view_issues_show_description_bottom, :partial => "issues/iac_show_hook"
  #render_on :view_issues_edit_notes_bottom, :partial => "issues/iac_edit_hook"
  render_on :view_issues_form_details_top,    :partial => "issues/form/details/top"
  render_on :view_issues_form_details_bottom, :partial => "issues/form/details/bottom"
  render_on :view_projects_show_right, :partial => "project/list_of_so"

#  render_on :view_issues_form_details_bottom,     :partial => "issue/author_as_checker"
end
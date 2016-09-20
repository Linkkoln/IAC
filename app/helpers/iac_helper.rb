module IacHelper
  include IssuesHelper

  class FieldsRows < IssueFieldsRows
  end

  def fields_rows
    r = FieldsRows.new
    yield r
    r.to_html
  end
end
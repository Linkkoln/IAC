class PrinterCategory < ActiveRecord::Base
  unloadable

  has_many :printers

  include Redmine::SafeAttributes

  scope :sorted, lambda {order(:brand, :model)}
  scope :active, lambda {where(active: 1)}

  attr_accessible 'brand' ,'model','cartridge', :active
  safe_attributes 'brand' ,'model','cartridge', :active

  def name
    brand+' '+model
  end
end

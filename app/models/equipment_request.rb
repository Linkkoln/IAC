#!/bin/env ruby
# encoding: utf-8
class EquipmentRequest < ActiveRecord::Base
  unloadable
  belongs_to :issue,           autosave: false, inverse_of: :equipment_request
  belongs_to :equipment,       autosave: false, inverse_of: :equipment_request
  belongs_to :service_request, autosave: true,  inverse_of: :equipment_request, foreign_key: 'request_id', dependent: :destroy
end

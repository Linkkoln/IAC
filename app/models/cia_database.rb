#!/bin/env ruby
# encoding: utf-8
require 'securerandom'

class CiaDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "cia_#{Rails.env}".to_sym
  self.sequence_name = 'gn_global'


  before_create :set_uuid
  before_save  :last_update

  protected
    def set_uuid
      self.recuuid = SecureRandom.uuid
    end

    def last_update
      unless self.class.name == "ServiceRequestEquipment" || self.class.name == "EquipmentCategory"
          self.lastupdate = DateTime.current
      end
    end
end

class RdbDatabase < CiaDatabase
  self.table_name = "RDB$DATABASE"

  def next_id
    self.find_by_sql("select gen_id(gn_global, 1) as gen from RDB$DATABASE").first.gen
  end
end

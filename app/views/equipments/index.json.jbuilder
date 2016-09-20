json.array!(@equipments) do |terminal_equipment|
  json.extract! terminal_equipment, :id, :stationname, :netusetype, :equipmenttype, :ownerid, :setplaceid, :osid, :f, :ram, :remark, :cd_dvd, :invnumber, :isinheritedinvnumber, :ciauchetnumber, :uchetname, :procesorid, :statusid, :ramtypeid, :recuuid, :dtleqtypeid, :warrantyenddate, :getdate, :manufacturedt, :hddsize, :usbports, :ipadress, :netname, :checkdate, :ownerequipmentid, :dtleqtypeidstr, :buhuchetid, :sourceid, :sernumber, :lastupdate, :lastunloaddt, :bldgaddressid
  json.url terminal_equipment_url(terminal_equipment, format: :json)
end

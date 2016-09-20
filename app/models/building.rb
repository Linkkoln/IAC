#buildings
# organization_id:integer
# post_index:string
# locality_place:string
# street:string
# num:string
# ordinal:integer
# institution_address_id:integer

class Building < ActiveRecord::Base
  unloadable
  belongs_to :organization
  belongs_to :institution_address, dependent: :destroy
  has_many :floors

  def synchronize
    if institution_address
      if institution_address.lastupdate > updated_at
        load_from_institution_address
      else
        save_to_institution_address
      end
    else
      self.destroy
    end
  end

  def name
    "Здание №#{ordinal}"
  end

  def full_address
    "#{street}, #{num}, #{locality_place}, #{post_index}"
  end

  def load_from_institution_address
    #institutionid, postindex, localityplace, street, buldingnum, fulladdres, internalnum
    a = self.institution_address
    self.post_index     = a.postindex
    self.locality_place = a.localityplace
    self.street         = a.street
    self.num            = a.buldingnum
    self.ordinal        = a.internalnum
    self.save
  end

  def save_to_institution_address
    #institutionid, postindex, localityplace, street, buldingnum, fulladdres, internalnum
    a = self.institution_address
    a.institutionid = organization.oa_id_iac
    a.postindex     = post_index
    a.localityplace = locality_place
    a.street        = street
    a.buldingnum    = num
    a.fulladdres    = full_address
    a.internalnum   = ordinal
    a.save
  end
end

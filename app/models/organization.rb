#t.string   "name",                     limit: 255
#t.string   "code",                     limit: 255
#t.text     "address",                  limit: 65535
#t.string   "telefone",                 limit: 255
#t.integer  "organization_category_id", limit: 4
#t.integer  "engineer_id",              limit: 4
#t.string   "employee_fio",             limit: 255
#t.string   "employee_position",        limit: 255
#t.integer  "responsible_person_id",    limit: 4
#t.datetime "created_at",                             null: false
#t.datetime "updated_at",                             null: false
#t.integer  "oa_id_iac",                limit: 4
#t.integer  "court_category_id_iac",    limit: 4
#t.integer  "oa_id_usd",                limit: 4
#t.integer  "project_id",               limit: 4
#t.string   "phone_code",               limit: 255
#t.string   "district_name",            limit: 255
#t.string   "name_r",                   limit: 255
#t.string   "head_name",                limit: 255
#t.string   "head_name_r",              limit: 255
#t.string   "head_short_name",          limit: 255
#t.string   "head_short_name_r",        limit: 255
#t.integer  "count_of_judges",          limit: 4
#t.integer  "full_time_staff",          limit: 4

#synchronize_at

class Organization < ActiveRecord::Base
  unloadable

  # Условности, которые надо соблюдать в редмайне, для защиты бд
  #     attr_accessible :name
  #     attr_accessible :name, :is_admin, :as => :admin
  attr_accessible  :name, :code, :address, :telefone, :employee_fio, :employee_position, :oa_id_usd, :phone_code,
                   :district_name, :name_r, :head_name, :head_name_r, :head_short_name, :head_short_name_r,
                   :count_of_judges, :full_time_staff


  after_save :save_to_institution

  belongs_to :institution,  foreign_key: 'oa_id_iac', autosave: false, inverse_of: :organization
  belongs_to :organization_category
  belongs_to :engineer, class_name: "User"
  belongs_to :responsible_person, class_name: "Employee"
  belongs_to :project
  has_many   :buildings

  def equipments
    Equipment.where("SETPLACEID = #{oa_id_iac}")
  end

  def synchronize
    load_from_institution
    #if institution.lastupdate > updated_at
    #  load_from_institution
    #else
    #  save_to_institution
    #end
    buildings_to_create = self.institution.institution_addresses.ids - self.buildings.pluck(:institution_address_id)
    buildings_to_create.each do |aid|
      building = buildings.build
      building.institution_address = InstitutionAddress.find(aid)
      building.load_from_institution_address
      building.save
    end
  end

  def places_for_select
    @buildings = Building.where(organization: id).preload(floors: [:rooms, :places])
    with_building = @buildings.size > 1
    pl = []
    @buildings.each do |building|
      building_part_name = with_building ? building.name + ' > ' : ''
      building.floors.each do |floor|
        floor_part_name = building_part_name + "#{floor.name} > "
        floor.rooms.each do |room|
          room_part_name = floor_part_name + "#{room.name} > "
          room.places.each do |place|
            full_place_name = room_part_name + place.name
            pl << [full_place_name, place.id]
          end
        end
      end
    end
    pl
  end

  private

  def load_from_institution
    self.name       = institution.name
    #self.code      = institution.vn_code
    #address
    #telefone
    #self.organization_category_id = case institution.levelcodid
    #engineer_id
    #employee_fio
    #employee_position
    #responsible_person_id
    #oa_id_iac
    #court_category_id_iac
    #self.oa_id_usd = institution.buhuchetcode
    #project_id
    self.phone_code = institution.phonecode
    self.district_name = institution.districtname
    self.name_r = institution.name_r
    self.head_name = institution.predname
    self.head_name_r = institution.predname_r
    self.head_short_name = institution.shortpredname
    self.head_short_name_r = institution.shortpredname_r
    self.count_of_judges = institution.judgecount
    self.full_time_staff = institution.shtatcount
    self.save
  end

  def save_to_institution
    #PK	  FK	Field	Domain	Type	NN	Default	Description
    #ID	 	                INTEGER	 	 	Первичный ключ
      #vn_code	    VCH0008	VARCHAR(8)	 	 	Код объекта автоматизации в ГАС "Правосудие"
      #phonecode	  VCH0010	VARCHAR(10)	 	 	Региональный телефонный код
      #name	        VCH0256	VARCHAR(256)	 	 	Наименование учреждения
      #districtname	VCH0256	VARCHAR(256)	 	 	Наименование муниципального образования
      #name_r	      VCH0256	VARCHAR(256)	 	 	Наименование учреждения в род. падеже
    ##RECUUID	    CHR0036	CHAR(36)	 	 	UUID записи
      #predname	    VCH0080	VARCHAR(80)	 	 	Руководитель учреждения
    #ISLEGALENTITY	 	    INTEGER	 	 	Признак "юридическое лицо": 1 - ДА 0 - НЕТ
    #DEPARTMENTID	 	      INTEGER	 	 	Код территориального подразделения (производственного участка) ИАЦ: спр. 37
      #fullname	    VCH0256	VARCHAR(256)	 	 	Полное наименование учреждения
      #buhuchetcode	VCH0012	VARCHAR(12)	 	 	Код учреждения в системе бухгалтерского учета балансоднржателя
    #CLONNAME	    VCH0030	VARCHAR(30)
      #levelcodid	 	        INTEGER	 	 	Код уровня ОА: спр.51
    #IACCODE	 	          INTEGER	 	 	Код ИАЦ, обслуживающего объект
    #FULLCODE	    VCH0050	VARCHAR(50)	 	 	Строковый структурированный код учреждения
      #shortpredname	VCH0050	VARCHAR(50)	 	 	Сокращенное представление руководителя учреждения
    #CAPTION	    VCH0050	VARCHAR(50)	 	 	Наименование для заголовков
    #LASTUPDATE	  TRANSPORTABLE_DATE	TIMESTAMP	 	 	Последняя дата - время изменения записи
    #LASTUNLOADDT	TRANSPORTABLE_DATE	TIMESTAMP	 	 	Последняя дата - время выгрузки (пока не используется)
    #SUBJECTCODE	VCH0003	VARCHAR(6)	 	 	Код субъекта
      #judgecount	 	        INTEGER	 	 	Для судов: составность суда
      #shtatcount	 	        INTEGER	 	 	Для судов: штатная численность суда
      #predname_r	  VCH0080	VARCHAR(80)	 	 	Руководитель объекта автоматизации в род падеже
      #shortpredname_r	VCH0050	VARCHAR(50)	 	 	Руководитель объекта автоматизации в род падеже (сок. версия)
    #PUBLICEMAIL	VCH0080	VARCHAR(80)	 	 	Публичный адрес электронной почты
    #INNEREMAIL	  VCH0080	VARCHAR(80)	 	 	Ведомственный адрес электронной почты
    #GROUPTYPEID	 	      INTEGER	 	 	Код групповой принадлежности: спр.90

    institution.name      = name
    institution.fullname  = name
    institution.vn_code   = code
    #address
    #telefone
    #organization_category_id
    #engineer_id
    #employee_fio
    #employee_position
    #responsible_person_id
    #institution.levelcodid   = case court_category_id_iac #Тип организации
    institution.buhuchetcode = oa_id_usd
    #project_id
    institution.phonecode    = phone_code
    institution.districtname = district_name
    institution.name_r       = name_r
    institution.predname     = head_name
    institution.predname_r   = head_name_r
    institution.shortpredname  = head_short_name
    institution.shortpredname_r = head_short_name_r
    institution.judgecount      = count_of_judges
    institution.shtatcount      = full_time_staff
    #institution.departamentid = self. #Данные об инженере
    institution.save
  end

end
# PK	FK	Field	Domain	Type	NN	Default	Description
# id	 	INTEGER	 	 	Первичный ключ
# recuuid	CHR0036	CHAR(36)	 	 	UUID записи
# institutionid	 	INTEGER	 	 	Код учреждения INSTITUTION.ID
# postindex	VCH0006	VARCHAR(6)	 	 	Почтовый индекс
# localityplace	VCH0128	VARCHAR(128)	 	 	Населеный пункт
# street	VCH0080	VARCHAR(80)	 	 	Улица
# buldingnum	VCH0020	VARCHAR(20)	 	 	номер дома
# fulladdres	VCH0256	VARCHAR(256)	 	 	Полный адрес
# internalnum	 	SMALLINT
# isisolatedsystem	 	SMALLINT
# lastupdate	TRANSPORTABLE_DATE	TIMESTAMP
# lastunloaddt	TRANSPORTABLE_DATE	TIMESTAMP
# a.id, a.recuuid, a.institutionid, a.postindex, a.localityplace, a.street, a.buldingnum, a.fulladdres, a.internalnum,
#     a.isisolatedsystem, a.lastupdate, a.lastunloaddt
# a.id, a.recuuid, a.institution_id, a.post_index, a.locality_place, a.street, a.num, a.full_address, a.internalnum,
#     a.isisolatedsystem, a.lastupdate, a.lastunloaddt

class InstitutionAddress < CiaDatabase
  self.table_name = "institutionaddres"
  self.primary_key = 'id'
  belongs_to :institution, foreign_key: "institutionid"
end


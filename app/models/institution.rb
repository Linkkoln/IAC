#PK	  FK	Field	Domain	Type	NN	Default	Description
#ID	 	                INTEGER	 	 	Первичный ключ
#VN_CODE	    VCH0008	VARCHAR(8)	 	 	Код объекта автоматизации в ГАС "Правосудие"
#PHONECODE	  VCH0010	VARCHAR(10)	 	 	Региональный телефонный код
#NAME	        VCH0256	VARCHAR(256)	 	 	Наименование учреждения
#DISTRICTNAME	VCH0256	VARCHAR(256)	 	 	Наименование муниципального образования
#NAME_R	      VCH0256	VARCHAR(256)	 	 	Наименование учреждения в род. падеже
#RECUUID	    CHR0036	CHAR(36)	 	 	UUID записи
#PREDNAME	    VCH0080	VARCHAR(80)	 	 	Руководитель учреждения
#ISLEGALENTITY	 	    INTEGER	 	 	Признак "юридическое лицо": 1 - ДА 0 - НЕТ
#DEPARTMENTID	 	      INTEGER	 	 	Код территориального подразделения (производственного участка) ИАЦ: спр. 37
#FULLNAME	    VCH0256	VARCHAR(256)	 	 	Полное наименование учреждения
#BUHUCHETCODE	VCH0012	VARCHAR(12)	 	 	Код учреждения в системе бухгалтерского учета балансоднржателя
#CLONNAME	    VCH0030	VARCHAR(30)
#LEVELCODID	 	        INTEGER	 	 	Код уровня ОА: спр.51
#IACCODE	 	          INTEGER	 	 	Код ИАЦ, обслуживающего объект
#FULLCODE	    VCH0050	VARCHAR(50)	 	 	Строковый структурированный код учреждения
#SHORTPREDNAME	VCH0050	VARCHAR(50)	 	 	Сокращенное представление руководителя учреждения
#CAPTION	    VCH0050	VARCHAR(50)	 	 	Наименование для заголовков
#LASTUPDATE	  TRANSPORTABLE_DATE	TIMESTAMP	 	 	Последняя дата - время изменения записи
#LASTUNLOADDT	TRANSPORTABLE_DATE	TIMESTAMP	 	 	Последняя дата - время выгрузки (пока не используется)
#SUBJECTCODE	VCH0003	VARCHAR(6)	 	 	Код субъекта
#JUDGECOUNT	 	        INTEGER	 	 	Для судов: составность суда
#SHTATCOUNT	 	        INTEGER	 	 	Для судов: штатная численность суда
#PREDNAME_R	  VCH0080	VARCHAR(80)	 	 	Руководитель объекта автоматизации в род падеже
#SHORTPREDNAME_R	VCH0050	VARCHAR(50)	 	 	Руководитель объекта автоматизации в род падеже (сок. версия)
#PUBLICEMAIL	VCH0080	VARCHAR(80)	 	 	Публичный адрес электронной почты
#INNEREMAIL	  VCH0080	VARCHAR(80)	 	 	Ведомственный адрес электронной почты
#GROUPTYPEID	 	      INTEGER	 	 	Код групповой принадлежности: спр.90

class Institution < CiaDatabase
  self.table_name    = 'institution'
  self.primary_key   = 'id'
  self.sequence_name = 'gn_global'
  has_one :organization,  foreign_key: 'oa_id_iac', autosave: false, inverse_of: :institution

  has_many :institution_addresses, foreign_key: "institutionid"

end
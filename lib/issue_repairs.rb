module Iac
  module IssueRepairs

    REQUEST_CF = {
        inventary_number: 22,
        serial_number: 21
    }

    def request
      equipment_request.service_request if equipment_request
    end

    def equipment
      equipment_request.equipment if equipment_request
    end

    # Принимаем на борт и обрабатываем массив хешей [check1], [check2], [exec]
    def service_request=(values)
      service_request.check1.safe_attributes = values['check1'] if values['check1'].present?
      if values['check2'].present?
        service_request.build_check2 if service_request.check2.nil?
        service_request.check2.safe_attributes = values['check2']
      end
      service_request.executant.safe_attributes = values['exec'] if values['exec'].present?
    end

    def repair?()             self.full_tracker_name == 'Ремонт'; end
    def equipment_category()    @e_cat_nam||= equipment.equipment_category.name if equipment; end
    def invnumber()             @invnumber||= equipment.invnumber  if equipment; end
    def sernumber()             @sernumber||= equipment.sernumber  if equipment; end
    def equipment_category_id() @eq_cat_id||= equipment.equipment_category.id if equipment_request; end
    def any_equipments_by_inventory?() equipments_by_inventory.nil? || equipments_by_inventory.count > 0; end

    def repair_num
      "#{project.oa_code}-#{request.regnum}/#{request.regyear}" if request
    end

    # Возвращает список оборудования с таким же инвентарным номером
    def equipments_by_inventory
      inventory = self.cf_by_name('Инв. №')
      if inventory.length > 3
        Equipment.where("INVNUMBER LIKE '%#{inventory}%' and setplaceid = #{oa_id_iac}")
      else
        nil
      end
    end

    def repair_validate
      return true unless (tracker.name =='Ремонт')||request
      # Проверяем что бы хронология была строго последовательной:
      # + regdate (= start_date)
      # + check1.checkdate              - >= regdate
      # + executant.senddate            - >= check1.checkdate
      # - executant.sendtoservicecentre - >= senddate
      # - executant.getdate             - >= sendtoservicecentre
      # - check2.checkdate              - >= getdate||senddate
      # - executant.sendto_oadt         - >= check2.checkdate||getdate||senddate

      if request.check1
        if request.check1.checkdate.nil?
          unless status_id == 1
            errors.add :base, "Дата диагностики для данного статуса должна быть указана"
          end
        else
          if request.check1.checkdate < request.regdate
            errors.add :base, "Дата диагностики не может быть меньше Даты начала (Даты заявки)"
          end
          if request.executant.senddate.nil?
            unless [Repairs::STATUS_NEW, Repairs::STATUS_FORMED, Repairs::STATUS_WRITTEN_OFF, Repairs::STATUS_WRITE_OFF_USD].include? status_id
              errors.add :base, "Дата поступления для данного статуса должна быть указана"
            end
          else # sr.check1.checkdate && sr.executant.senddate
            if request.executant.senddate < request.check1.checkdate
              errors.add :base, "Дата поступления не может быть меньше Даты первичной проверки"
            end
            if !request.executant.sendtoservicecentre.nil? && request.executant.sendtoservicecentre < request.executant.senddate
              errors.add :base, "Дата отправки в СЦ не может быть меньше Даты поступления"
            end
          end
        end
      end

      unless request.executant.getdate.nil? # Если указана дата поступления из СЦ
        if request.executant.sendtoservicecentre.nil?
          errors.add :base, "Необходимо указать дату отправки в СЦ"
        else
          if request.executant.getdate < request.executant.sendtoservicecentre
            errors.add :base, "Дата поступления из СЦ не может быть меньше чем Дата отправки в СЦ"
          end
        end
      end

      if request.check2 && !request.check2.checkdate.nil?
        if !request.executant.senddate.nil? && request.check2.checkdate < request.executant.senddate
          errors.add :base, "Дата повторной диагностики не может быть меньше чем Дата поступления"
        end
        if !request.executant.getdate.nil? && request.check2.checkdate < request.executant.getdate
          errors.add :base, "Дата повторной диагностики не может быть меньше чем Дата возврата из СЦ"
        end
      end

      unless request.executant.sendto_oadt.nil?
        if request.check2 && !request.check2.checkdate.nil? && request.executant.sendto_oadt < request.check2.checkdate
          errors.add :base, "Дата отправки на ОА не может быть меньше чем Дата повторной диагностики"
        end
        if !request.executant.senddate.nil? && request.executant.sendto_oadt < request.executant.senddate
          errors.add :base, "Дата отправки на ОА не может быть меньше чем Дата поступления"
        end
        if !request.executant.getdate.nil? && request.executant.sendto_oadt < request.executant.getdate
          errors.add :base, "Дата отправки на ОА не может быть меньше чем Дата возврата из СЦ"
        end
      end
    end

    # Функция копирует параметры оборудования в текущую задачу
    def synchronize_from_equipment_params
      self.custom_field_values = {
          REQUEST_CF[:inventary_number] => invnumber,
          REQUEST_CF[:serial_number]  => sernumber
      }
      self.save
    end

    private

    def repair_after_save
      return unless request

      # Если текущий статус не из группы списание и существует check2 (т.е. вернулись из стадии "списно"), то удаляем
      if request.check2 && !status_write_off?(self.status_id.to_i)
        request.executant.eqpmntcheckid = request.check1_id
        request.executant.save
        request.check2.check_conclusions.clear
        request.check2.check_failure_causes.clear
        request.check2.delete
      end

      request.executant.save if request.executant.changed?
    end
  end
end
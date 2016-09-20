module Cartridges

  STATUS_NEW           = 1  # Новая
  STATUS_FORMED        = 29 # Сформирована
  STATUS_TAKEN         = 30 # Принята
  STATUS_WORK          = 2 # В работе
  STATUS_PASSED        = 28 # На выдачу
  STATUS_CLOSE         = 5  # Закрыто


  def cartridge_updete context
    current_status = get_status_id Issue.find(context[:issue].id).status.name #проверяем текущий статус
    new_status     = get_status_id context[:issue].status.name

    # begin Раздел обработки Общих задач
    if context[:issue].project.identifier == 'all' &&
        ((current_status == 4 && new_status == 5) ||
            (current_status == 5 && new_status == 4))
      # tracker.name == 'Картриджи'
      # project.identifier == 'all'
      # Текущий статус задачи "В работе"
      #Устанавливаем признак по которому потом поймем что надо закрывать подчиненные задачи0
      context[:params].merge!({update_descendants_status: true})
    end

    #Раздел обработки задач Объектов автоматизации
    if context[:issue].project.identifier != 'all' &&
        context[:params][:pc]

      context[:params][:pc].each { |id, value|
        pi = PrintersIssue.find(id)
        if value.to_i == 0 && current_status == 1 #Удаляем картриджи у новых задач
          pi.destroy
        else
          case current_status
            when 1 then pi.crtr_plan=value
            when 2 then pi.crtr_real=value
            when 3 then pi.crtr_send=value
          end
          pi.save
        end
      } unless new_status < current_status
      PrintersIssue.where(issue_id: context[:issue].id).each { |pi|
        case new_status
          when 2 then pi.crtr_real = pi.crtr_plan
          when 3 then pi.crtr_send = pi.crtr_real
        end
        pi.save
      }  if new_status > current_status
    end
  end

  private

  def common_cartridges_filled
    @issue.cartridges_by_type.each do |item|
      tmp_s = item.send_count
      tmp_r = @restored[item.cartridge]
      tmp_k = @killed[item.cartridge]
      if tmp_s >= (tmp_r + tmp_k)
        r_part = tmp_r/tmp_s
        k_part = tmp_k/tmp_s
        @issue.cartridges.joins(printer: :printer_category)
            .where(printer_categories: {cartridge: item.cartridge})
            .order('send').all.each do |pc|
          pc_r = (pc.send * r_part).ceil
          pc_r = tmp_r if tmp_r < pc_r
          tmp_r = tmp_r - pc_r

          pc_k = (pc.send * k_part).ceil
          pc_k = tmp_k if tmp_k < pc_k
          tmp_k = tmp_k - pc_k

          pc.filled   = pc.send - (pc_r + pc_k)
          pc.restored = pc_r
          pc.killed   = pc_k
          pc.save
        end
      else
        @error = true
      end
    end
  end

  def get_status_id status_name
    case status_name
      when 'Новая'        then  1
      when 'Сформирована' then  2
      when 'Принята'      then  3
      when 'В работе'     then  4
      when 'На выдачу'    then  5
      when 'Закрыта'      then  6
      else                      nil
    end
  end

  def get_status_name id
    case id
      when 1 then 'Новая'
      when 2 then 'Сформирована'
      when 3 then 'Принята'
      when 4 then 'В работе'
      when 5 then 'На выдачу'
      when 6 then 'Закрыта'
      else        nil
    end
  end
end
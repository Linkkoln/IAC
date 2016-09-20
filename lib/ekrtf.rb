#!/bin/env ruby
# encoding: utf-8
module Ekrtf
  ##
  # Для генерации отчета по шаблону необходимо предварительно задать:
  #  1) значения статических переменных отчета <%Name%>  необходимо задавать в хеше параметров pr.merge! Name => Value
  #  2) основной список данных в виде инстансной переменной с добавлением "s" в конце
  #     <%Start(list)%> ... <%end%> - информация между тегами будет продублирована для каждого элемента списка lists
  #     <%list.param%> - в шаблоне допустимо использовать только одноуровневый запрос параметров
  #     @lists = Model.all
  #     в хеше параметров определяем pr.merge! list => :master
  #
  #  3) вложенный список - список, который зависит от основного или от другого вложенного списка
  #     в шаблоне используется как и основной
  #     Определяться должен как инстансная переменная с добавлением _detail в виде Proc, внутри которой определяем уже
  #     инстансную переменную с вложенным списоком, которая будет переопределяться каждый раз при проходе основного списка
  #     opt_detail = Proc.New { @opts = Opt.where(column: @list.method).all}
  #     в хеше параметров обязательно определяем pr.merge! opt => :detail#
  #  4) любые объекты в виде инстансных переменных, в шаблон допустимо вставлять только в виде доступа к методам объекта
  #     <%issue.param%>
  #  5) Proc в виде инстансной переменной, принимающей один параметр, который тоже должен являться инстансной переменной
  #     <%function[list]%>
  #     @function = Proc.new {|list| list.param * value }
  #
  #
  # #

  PORUCHENIYA   = ['15.05.2014','20.02.2015']
  TEMPLATESPATH = Dir.pwd + '/plugins/iac/templates/'


  def common_static_variable_of_project pr, project
    pr.merge! 'OAName'    => project.oa_name
    pr.merge! 'OACode'    => project.oa_code
    pr.merge! 'OAAddr'    => project.cf_by_name("Адрес ОА")
    pr.merge! 'OAphone'   => project.cf_by_name("Телефон ОА")
    pr.merge! 'OADolzn'   => project.cf_by_name("Ответственный на ОА (Должн-ть)")
    pr.merge! 'OAFio'     => project.cf_by_name("Ответственный на ОА (ФИО)")
    pr.merge! 'OASystem'  => project.system_code
    pr.merge! 'loanee_fio'      => project.identifier == 'kks' ? "С.Н. Свашенко" : "И.И. Гарбовский"
    pr.merge! 'loanee_full_name'=> project.identifier == 'kks' ? "Свашенко Сергей Николаевич" : "Гарбовский Иосиф Иванович"
    pr.merge! 'loanee_basis'    => project.identifier == 'kks' ?
                  "федерального закона от 31.12.1996 г. № 1-ФКЗ \"О Судебной системе Российской Федерации\"" :
                  "федерального закона от 08.01.1998 г. № 7-ФЗ \"О Судебном департаменте при Верховном Суде Российской Федерации\" и Положения об Управлении Судебного департамента в Краснодарском крае"
    pr.merge! 'loanee_pos'      => project.identifier == 'kks' ? "Заместитель председателя Краснодарского краевого суда" : "Начальник Управления судебного департамента в Краснодарском крае"
  end

  #Генератор отчетов. Идея такова что ему должно быть пофиг какие параметры обрабатывать - обработка должна быть универсальной
  def generate_rtf_by_template params, file_name_input, file_name_output
    file_name_input  = TEMPLATESPATH + file_name_input

    # Загружаем шаблон
    begin
      template  = File.open(file_name_input,"r") {|file|file.read}
    rescue BlogDataNotFound
      STDERR.puts "Файл #{file_name_input} не найден"
    rescue Exception => exc
      STDERR.puts " Общая ошибка загрузки #{file_name_input}: #{exc.message}"
    end

    temp = [[],[],[],[],[]] #Временная переменная для хранения кусков шаблока на различных уровнях вложенности списков
    u    = ['','','','',''] #Временная переменная для хранения наименования списка на каждом уровне вложенности
    a = template.split(/(<%start\(\w+\)%>|<%end%>)/) #Парсим шаблон и разбиваем его на элементы в массив

    # Приводим массив к виду [String, Hash, String, ...], где String - кусок шаблона без списка, Hash - список,
    # в котором key - наименование списка, value - массив с рекурсивно аналогичной структурой
    k = 0 #уровень вложенности списка = 0
    del_par = false #Временная переменная для определения начала списка что бы удалить ведущий \par
    a.map do |s|
      if s =~ /<%start\((\w+)\)%>/ #Начало очередного вложенного списка, инициируем переменные
        k = k+1
        u[k] = $1
        temp[k] = []
        del_par = true
      elsif s =~ /<%end%>/ #Конец текущего вложенного списка
        temp[k-1] << {u[k].to_s => temp[k]} # Добавляем к массиву, предыдущего уровня вложенности хэш со сформированным списком
        k=k-1                               # Уменьшаем уровень вложенности списка
        del_par = true
      else #Простой текст
        if del_par #В строке перед началом списка и после списка удаляем ведущий перенос строки \par
          s.sub!('\par ',' ')
        end
        temp[k] << s #Добавляем к массиву, текущего уровня вложенности новый элемент списка
        del_par = false
      end
    end
    a = temp[0]

    # В этом блоке все переменные заменяем на их значения и полученный текст запихиваем в переменную output
    @output = ''
    replace_rtf a, params
    @output = @output.recode_for_rtf

    send_data @output,
              :filename => file_name_output,
              :type => 'application/msword',
              :disposition => 'attachment'
  end

  def replace_rtf(ar, params)
    ar.each do |s|
      if s.class == String
        t=String.new(s)
        t.gsub!(/<%(\w+)%>/)          { params[$1].to_s.gsub(/\n/,'\\par ') }
        t.gsub!(/<%(\w+)\.(\w+)%>/)   { self.instance_variable_get("@#{$1}").send($2).to_s.gsub(/\n/){'\\par '} }
        t.gsub!(/<%(\w+)\[(\w+)\]%>/) { self.instance_variable_get("@#{$1}").call(self.instance_variable_get("@#{$2}")) }
        @output << t
      else #если не строка, то хэш
        #В цикле подставляем значения элементов списка в pr и запускаем в рекурсию текущий блок
        s.each do |list, sub_a| #в нашем случае хэш всегда имеет только одну пару
          # Если список подчиненный, то его надо переопределить
          if params[list] == :detail
            self.instance_variable_get("@#{list}_detail").call
          end

          self.instance_variable_get("@#{list}s").each do |item|
            self.instance_variable_set("@#{list}", item)
            replace_rtf2 sub_a, params
          end
        end
      end
    end
  end



end
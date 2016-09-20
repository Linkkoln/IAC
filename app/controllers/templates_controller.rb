#!/bin/env ruby
# encoding: utf-8

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
# #

class TemplatesController < ApplicationController
  PORUCHENIYA   = ['15.05.2014','20.02.2015']
  TEMPLATESPATH = Dir.pwd + '/plugins/iac/templates/'

  before_filter :set_common_params

  def make_act_co3
    template = 'co3' #params[:file]
    # Формирование списка переменных отчета и наполнение значениями
    @project = Project.find_by_identifier(params[:id])
    month = params[:month].to_i
    year = params[:year].to_i
    from = "01.#{month}.#{year}".to_date
    to   = from.end_of_month
    #Загружаем список задач и прописываем алиасы
    @issues = Issue.
        where(project_id: @project.id, due_date: from..to, tracker_id: [3,11,12]).
        order("due_date").all
    #Статичные переменные
    pr = {}
    common_static_variable_of_project pr, @project
    pr.merge! 'DatePoruch'=> Order.order_date(to.month_last_work_day).strftime("%d.%m.%Y")
    pr.merge! 'ActNum'    => month.to_s
    pr.merge! 'ActDate'   => to.month_last_work_day.strftime("%d.%m.%Y")
    pr.merge! 'year'      => year.to_s
    pr.merge! 'issue' => :master
    #Запускаем генератор отчета, которому передаем список переменных, входной и выходной файл
    generate_rtf_by_template2 pr, "#{template}.rtf", "#{template}-#{pr['OACode']}-#{pr['ActNum']}-#{pr['year']}.rtf"
  end

  def make_act_co6
    template = 'co6_'+params[:num]
    @project_id = params[:project]
    @project = Project.find_by_identifier(@project_id)
    num =  params[:num]

    #Статичные переменные
    pr = {}
    common_static_variable_of_project pr, @project
    pr.merge! 'ActDate'   => num == '28' ? '10.06.2015' :
                             num == '29' ? '02.11.2015' :
                             num == '30' ? '02.06.2016' : ''
    pr.merge! 'DatePoruch'=> Order.order_date(pr['ActDate']).strftime("%d.%m.%Y")
    pr.merge! 'Year'    => pr['ActDate'].to_date.year
    #pr.merge! 'ActNum'      => num

    #Запускаем генератор отчета, которому передаем список переменных, входной и выходной файл
    generate_rtf_by_template2 pr, "co6-#{num}.rtf", "co6-#{pr['OACode']}-#{num}-#{pr['Year']}.rtf"
  end


  def report_co3
    template = "report_so3"
    year = params[:year].to_i
    num =  params[:num].to_i
    type = params[:type]

    case type
      when 'quarter'
        @from = Date.new(year, (num-1)*3+1, 01)
        @to   = @from.end_of_quarter
      when 'half_year'
        @from = "#{num==1 ? '01.01':'01.06'}.#{year}".to_time
        @to   = "#{num==1 ? '30.06':'31.12'}.#{year}".to_time
    end

    pr = {}
    pr.merge! 'num'  => num
    pr.merge! 'year' => year
    pr.merge! 'issue' => :master
    pr.merge! 'tr'    => :detail

    @issues = Issue.
        select("project_id, month(due_date) as month, count(*) as c").
        where(due_date: @from..@to, tracker_id: [3,11,12]).
        group("project_id, month(due_date)").all

    @oa_code  = Proc.new {|issue| Project.find_by_id(issue.project_id).oa_code }
    @oa_name  = Proc.new {|issue| Project.find_by_id(issue.project_id).oa_name }
    @act_date = Proc.new {|issue| "01.#{issue.month}.#{year}".to_date.month_last_work_day.strftime('%d.%m.%Y') }

    @tr_detail = Proc.new {
      @trs = Issue.
          select("issues.project_id, trackers.name, month(issues.due_date), count(*) as c ").
          joins(:tracker).
          where("project_id = #{@issue.project_id} and month(issues.due_date) = #{@issue.month} and year(issues.due_date) = #{year} and tracker_id in (3,11,12)").
          group("issues.project_id, trackers.name").all
    }
    generate_rtf_by_template2 pr, "#{template}.rtf", "#{template}-2-2015.rtf"
  end

  def report_on_cartridges
    issue_id = param[:issue]
    quarter  = param[:quarter]
    year     = param[:year]
    act_date = '30.06.2015' if year == 2015 and quarter == 2

    pr = {}
    pr.merge! "act_date" => act_date

    @cartridges =  Issue.find_by_id(issue_id).cartridges
    #Issue.where(parant_id: [3942,3943,4617]).all.each{|i| issues << i.id}
    #@cartridges = PrintersIssue.joins(issues: :projects)
    #                  .joins('LEFT OUTER JOIN custom_values ON custom_values.customized_id = projects.id and custom_values.custom_field_id = 12')
    #                  .where(issue_id: issues).order(custom_values: :value)
    generate_rtf_by_template pr, "report_on_cartridges.rtf", "report_on_cartridges-#{issue_id}.rtf"
  end

  def make_file_for_cartridges
    issue_id = params[:id].to_i
    template = params[:file]
    @issue        = Issue.find_by_id(issue_id)
    #TODO Выполнить проверку, что задача из трекера Картриджи в противном случае вызвать ошибку

    @cartridges    = @issue.cartridges.all
    @cartr_by_types= @issue.cartridges_by_type
    @count_cartridges = @issue.count_cartridges
    @project       = @issue.project

    pr = {}
    common_static_variable_of_project pr, @project
    pr.merge! 'num'    => @issue.cf_by_name("Номер заявки")
    case template
      when 'common_request_for_cartridges' then count_cartridges = @count_cartridges.send_count
      when 'request_for_cartridges'        then count_cartridges = @count_cartridges.real_count
      when 'act_of_issuing_cartridges'     then count_cartridges = @count_cartridges.send_count
      else count_cartridges = 0
    end
    pr.merge! 'count'    => count_cartridges
    generate_rtf_by_template pr, "#{template}.rtf", "#{template}-#{issue_id}.rtf"
  end

protected

  def set_common_params
    pr = {}
    #common_static_variable_of_project pr, @project
  end

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
        @output << s.gsub(/<%(\w+)(\.\w+)?%>/) do
          if $2
            s=self.instance_variable_get("@#{$1}").send($2.delete!(".")).to_s
            s.gsub(/\n/){'\\par '}
          else
            s=params[$1].to_s
            s.gsub('\n','\\par ')
          end
        end
      else #если не строка, то хэш
        #В цикле подставляем значения элементов списка в pr и запускаем в рекурсию текущий блок
        s.each do |list, sub_a|
          self.instance_variable_get("@#{list}s").each do |item|
            self.instance_variable_set("@#{list}", item)
            replace_rtf sub_a, params
          end
        end
      end
    end
  end

  #Генератор отчетов. Идея такова что ему должно быть пофиг какие параметры обрабатывать - обработка должна быть универсальной
  def generate_rtf_by_template2 params, file_name_input, file_name_output
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
    replace_rtf2 a, params
    @output = @output.recode_for_rtf

    send_data @output,
              :filename => file_name_output,
              :type => 'application/msword',
              :disposition => 'attachment'
  end

  def replace_rtf2(ar, params)
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
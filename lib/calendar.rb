class Date
  HOLIDAYS = [
      '01.01.2015',
      '02.01.2015',
      '05.01.2015',
      '06.01.2015',
      '07.01.2015',
      '08.01.2015',
      '09.01.2015',
      '23.02.2015',
      '09.03.2015',
      '01.05.2015',
      '04.05.2015',
      '11.05.2015',
      '12.06.2015',
      '04.11.2015']

  def month_last_work_day
    pred_work_day self.end_of_month
  end

  def pred_work_day (day)
    if HOLIDAYS.include?(day.strftime('%d.%m.%Y')) or [0,6].include?(day.wday)
      pred_work_day(day-1)
    else
      day
    end
  end

end
class Order < ActiveRecord::Base
  unloadable

  def self.order_date(adate)
    Order.where('starting_date < ?', adate.to_date).maximum('starting_date')
  end
end

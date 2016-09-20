# t.integer :floor_id
# t.string :name
# t.integer :category
# t.string :area
# t.integer :ord
class Room < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes
  belongs_to :floor
  has_many :places

  safe_attributes :name, :area, :category, :move_to

  attr_protected :id

  serialize :point, Hash
  acts_as_list column: :ord, scope: :floor

  scope :ordered, ->{order(:ord)}

  CATEGORIES = {1=>:cabinets,
                2=>:courtrooms,
                3=>:halls,
                4=>:backrooms,
                100=>:another}

  def self.categories
    CATEGORIES
  end

  def self.categories_for_select
    CATEGORIES.map do |h|
      [Room.rus_name(h.first), h.first]
    end
  end

  def self.short_rus_name category
    case category
      when 1 then 'Каб.'
      when 2 then 'Зал'
      when 3 then 'Холл'
      when 4 then 'Сл.'
      when 100 then 'Пом.'
    end
  end

  def self.rus_name category
    case category
      when 1 then 'Кабинет'
      when 2 then 'Зал судебных заседаний'
      when 3 then 'Холл'
      when 4 then 'Служебное помещение'
      when 100 then 'Помещение'
    end
  end

  def category_tname
    Room.rus_name (self.category)
  end

  def work_places
    self.places.where(category: 1).count
  end

  def other_places
    self.places.where('category <> 1').count
  end

end

# t.integer :floor_id
# t.string :name
# t.integer :category
# t.string :point
# t.integer :ord
# t.integer :room_id
# t.integer :work_place_category
CATEGORIES = {
    1=> {name: :work_place,   rus_name: 'Рабочее место',        short_rus_name: 'Рабочее место'},
    2=> {name: :net_printer,  rus_name: 'Сетевой принтер',      short_rus_name: 'Сетевой принтер'},
    3=> {name: :info_kiosk,   rus_name: 'Информационный киоск', short_rus_name: 'Информационный киоск'},
    4=> {name: :vks,          rus_name: 'ВКС',                  short_rus_name: 'ВКС'},
    5=> {name: :avf,          rus_name: 'АВФ',                  short_rus_name: 'АВФ'},
    6=> {name: :rack,         rus_name: 'Серверная стойка',     short_rus_name: 'Серверная стойка'},
  100=> {name: :another,      rus_name: 'Другое',               short_rus_name: 'Другое'}
}

WORK_PLACE_CATEGORIES = {
    1 => {name: :judge,     rus_name: 'Судья',                          short_rus_name: 'Судья'},
    2 => {name: :assistant, rus_name: 'Помощник судьи',                 short_rus_name: 'Помощник'},
    3 => {name: :secretary, rus_name: 'Секретарь судебного заседания',  short_rus_name: 'Секретарь'},
  100 => {name: :other,     rus_name: 'Иной работник суда',             short_rus_name: 'Иной'}
}



class Place < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes


  belongs_to :floor
  belongs_to :room

  safe_attributes :name, :point_x, :point_y, :category, :move_to, :work_place_category, :room_id

  attr_protected :id

  serialize :point, Hash
  acts_as_list column: :ord, scope: :floor

  before_save do
    self.name = (0...2).map { ('a'..'z').to_a[rand(26)] }.join unless self.name
  end

  scope :ordered, ->{order(:ord)}

  def self.categories
    CATEGORIES
  end

  def self.categories_for_select
    CATEGORIES.map { |i| [i[1][:rus_name], i[0]] }
  end

  def self.work_place_categories
    WORK_PLACE_CATEGORIES
  end

  def self.work_place_categories_for_select
    WORK_PLACE_CATEGORIES.map do |i|
      [i[1][:rus_name], i[0]]
    end
  end

  def point_x() point[:x]; end
  def point_y() point[:y]; end
  def point_x=(v) point[:x] = v; end
  def point_y=(v) point[:y] = v; end

  def category_name
    CATEGORIES[category][:name] if CATEGORIES[category]
  end

  def category_rus_name
    CATEGORIES[category][:rus_name]
  end

  def category_full_rus_name
    s=CATEGORIES[category][:rus_name]
    s+=" (#{WORK_PLACE_CATEGORIES[work_place_category][:short_rus_name]})" if category==1&&work_place_category
    s
  end

  def full_name
    (room.floor.building.organization.buildings.count > 1 ? room.floor.building.name+' > ' : '')+
      room.floor.name+' > '+room.name+' > '+name
  end

  # def safe_attributes= (attrs)
  #   self.name      = attrs[:name] if attrs[:name]
  #   self.point[:x] = attrs[:point_x] if attrs[:point_x]
  #   self.point[:y] = attrs[:point_y] if attrs[:point_y]
  #   self.category  = attrs[:category] if attrs[:category]
  # end

  # before_save :set_point
  #
  # class Point
  #   attr_accessor :x, :y
  # end
  #
  # def point
  #   @point ||= begin
  #     point = read_attribute :point
  #     Point.new x: point[0], y: point[1]
  #   end
  # end
  #
  # private
  #
  # def set_point
  #
  # end
end

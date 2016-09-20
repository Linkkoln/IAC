class Floor < ActiveRecord::Base
  unloadable
  belongs_to :building
  has_many :rooms
  has_many :places
end

class RoleTrackers < ActiveRecord::Base
  unloadable

  belongs_to :roles
  belongs_to :trackers
end

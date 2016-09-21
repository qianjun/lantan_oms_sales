#encoding: utf-8
class StationServiceRelation < ActiveRecord::Base
  belongs_to :station
  belongs_to :product
end

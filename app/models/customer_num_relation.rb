#encoding: utf-8
class CustomerNumRelation < ActiveRecord::Base
  belongs_to :customer
  belongs_to :car_num
end

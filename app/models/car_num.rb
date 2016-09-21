#encoding: utf-8
class CarNum < ActiveRecord::Base
  has_one :customer_num_relation
end

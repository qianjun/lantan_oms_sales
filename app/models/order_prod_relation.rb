#encoding: utf-8
class OrderProdRelation < ActiveRecord::Base
  belongs_to :order
  belongs_to :product
  

end

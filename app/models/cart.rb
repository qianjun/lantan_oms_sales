#encoding: utf-8
class Cart < ActiveRecord::Base
  TYPES = {"Product" =>[0,1],"SvCard"=>[4],"PackageCard"=>[2]} #根据表加载对应的数据到购物车
  STATUS = {:NORMAL => 0,:USED => 1} #0 正常  1 已购买 或者删除
  scope :normal,where(:status=>STATUS[:NORMAL])
  
end

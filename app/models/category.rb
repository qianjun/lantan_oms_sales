#encoding: utf-8
class Category < ActiveRecord::Base
  has_many :products
  has_many :materials
  TYPES = {:material => 0, :good => 1, :service => 2,:OWNER =>3,:ASSETS =>4}     #0物料 1商品中的产品 2商品中的服务 3 付款类别 4 收款类别 5 资产类别
  TYPES_NAME = {0=>"物料",1=>"产品",2=>"服务",3=>"收付款",4=>"资产"}
  DATA_TYPES = [TYPES[:good],TYPES[:service]]

  #业务开单查询类别
  SEARCH_ITEMS = {0=>"卡类",1=>"产品",2=>"服务"}
  ITEM_NAMES = {:CARD => 0,:PROD => 1,:SERVICE => 2}
end

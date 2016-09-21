#encoding: utf-8
class Store < ActiveRecord::Base
  include ApplicationHelper
  has_many :stations
  has_many :reservations
  has_many :products
  has_many :sales
  has_many :work_orders
  has_many :svc_return_records
  has_many :goal_sales
  has_many :message_records
  has_many :notices
  has_many :package_cards
  has_many :staffs
  has_many :materials
  has_many :suppliers
  has_many :month_scores
  has_many :complaints
  has_many :sv_cards
  has_many :store_chain_relations
  has_many :depots
  has_many :customers
  has_many  :alipay_records
  belongs_to :city
  has_many :roles

  AUTO_SEND = {:YES =>1,:NO =>0}  #是否自动发送 1 自动发送 0 不自动发送
  STATUS = {
    :CLOSED => 0,       #0该门店已关闭，1正常营业，2装修中, 3已删除
    :OPENED => 1,
    :DECORATED => 2,
    :DELETED => 3
  }
  S_STATUS = {
    0 => "已关闭",
    1 => "正常营业",
    2 => "装修中",
    3 => "已删除"
  }
  EDITION_LV ={       #门店使用的系统的版本等级
    0 => "实用版",
    1 => "精英版",
    2 => "豪华版",
    3 => "旗舰版"
  }

end

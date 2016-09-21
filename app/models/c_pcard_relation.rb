#encoding: utf-8
class CPcardRelation < ActiveRecord::Base
  belongs_to :package_card
  belongs_to :customer
  has_one :order
  #  has_many :orders
  STATUS = {:INVALID => 0,:NORMAL => 1,:NOTIME =>2} #0 为无效 1 为正常卡 2 为过期/使用完
  STATUS_NAME = {2 => "过期/使用完", 1 => "正常使用",0=>"无效"}

end

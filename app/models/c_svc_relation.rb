#encoding: utf-8
class CSvcRelation < ActiveRecord::Base
  include ApplicationHelper
  has_many :svcard_use_records
  belongs_to :sv_card
  has_one :order
  belongs_to :customer

  STATUS = {:valid => 1, :invalid => 0}         #1有效的，0无效
  SEL_METHODS = {:PCARD => 2,:SV =>1,:DIS =>0 ,:BY_PCARD => 3, :BY_SV => 4,:PROD =>6,:SERV =>5}
  #1 购买储值卡 0  购买打折卡 2 购买套餐卡 3 通过套餐卡购买 4 通过打折卡购买 5 购买服务 6 购买产品
  SEL_PROD = [SEL_METHODS[:BY_PCARD],SEL_METHODS[:BY_SV],SEL_METHODS[:PROD],SEL_METHODS[:SERV]]
  SEL_SV = [SEL_METHODS[:SV],SEL_METHODS[:DIS]]
  


end

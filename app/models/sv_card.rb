#encoding: utf-8
class SvCard < ActiveRecord::Base
  has_many :svcard_prod_relations
  has_many :c_svc_relations
  belongs_to :store
  FAVOR = {:SAVE =>1,:DISCOUNT =>0} #1 储值卡 0 打折卡
  S_FAVOR = {1 => "储值卡", 0 => "打折卡"}
  STATUS = {:NORMAL => 1, :DELETED => 0} #状态 1正常 0删除
  
  USE_RANGE = {:LOCAL => 1, :CHAINS => 2}  #优惠卡使用范围 1仅本店，2连锁店
  S_USE_RANGE = {1 => "仅本店", 2 => "连锁店"}
  PER_PAGE = 10
  scope :normal_included, lambda{|store_id| where(:store_id => store_id, :status => STATUS[:NORMAL])}
  scope :on_weixin, lambda{|store_id| where(:store_id => store_id,:on_weixin => true)}

end

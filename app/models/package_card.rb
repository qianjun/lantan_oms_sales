#encoding: utf-8
class PackageCard < ActiveRecord::Base


  STAT = {:INVALID =>0,:NORMAL =>1}  #0 为失效或删除  1 为正常使用
  TIME_SELCTED = {:PERIOD =>0,:END_TIME =>1} #0 时间段  1  有效时间长度
  scope :is_normal, where(:status => true)
  scope :on_weixin, lambda{|store_id| where(:store_id => store_id,:on_weixin => true)}
end

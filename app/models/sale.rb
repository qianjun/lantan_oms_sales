#encoding: utf-8
class Sale < ActiveRecord::Base
  has_many :sale_prod_relations
  has_many :products, :through => :sale_prod_relations do
    def service
      where("is_service = true")
    end
  end

  belongs_to :store
  STATUS={:UN_RELEASE =>0,:RELEASE =>1,:DESTROY =>2} #0 未发布 1 发布 2 删除
  STATUS_NAME={0=>"未发布",1=>"已发布",2=>"已删除"}
  DISC_TYPES = {:FEE =>1,:DIS =>0} #1 优惠金额  0 优惠折扣
  DISC_TYPES_NAME = {1 => "金额优惠", 0 => "折扣"}
  DISC_TIME = {:DAY =>1,:MONTH =>2,:YEAR =>3,:WEEK =>4,:TIME =>0} #1 每日 2 每月 3 每年 4 每周 0 时间段
  DISC_TIME_NAME ={1=>"本年度每天",2=>"本年度每月",3=>"本年度每年",4=>"本年度每周" }
  SUBSIDY = { :NO=>0,:YES=>1} # 0 不补贴 1 补贴
  TOTAL_DISC = [DISC_TIME[:DAY],DISC_TIME[:MONTH],DISC_TIME[:YEAR],DISC_TIME[:WEEK]]
  scope :valid, where("((ended_at > '#{Time.now}' and disc_time_types = #{DISC_TIME[:TIME]}) or disc_time_types!= #{DISC_TIME[:TIME]})  and status=#{STATUS[:RELEASE]}")
  scope :on_weixin, lambda{|store_id| where(:store_id => store_id,:on_weixin => true)}

 
end

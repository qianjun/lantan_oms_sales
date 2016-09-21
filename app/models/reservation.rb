#encoding: utf-8
class Reservation < ActiveRecord::Base
  belongs_to :store
  belongs_to :customer
  belongs_to :car_num
  has_many :res_prod_relation, :dependent => :destroy

  STATUS = {:normal => 0, :cancel => 2, :confirmed => 1} #0  正常 1  确认预约 2 删除
  TYPES = {:PURPOSE =>0,:RESER => 1} #0 意向单 1 预约单
  scope :is_normal, lambda{|store_id,types| where(:store_id => store_id,:status=>STATUS[:normal],:types=>types)}
  PROD_TYPES = {:PRODUCT=>0,:SERVICE=>1,:PCARD=>2,:DISCOUNT=>3,:SAVE=>4} #预约单中 0 产品 1 服务 2 套餐卡 3 打折卡 4 储值卡
  def self.generate_code(store_id, time=nil)
    (time.nil? ? Time.now.strftime("%Y%m%d%H%M%S") : DateTime.parse(time).strftime("%Y%m%d%H%M%S"))+set_code(3)
  end

   def self.set_code(len)
    chars =  (0..9).to_a
    code_array = []
    1.upto(len) {code_array << chars[rand(chars.length)]}
    return code_array.join("")
  end

end

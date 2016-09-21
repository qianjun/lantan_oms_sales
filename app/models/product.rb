#encoding: utf-8
class Product < ActiveRecord::Base

  has_many :sale_prod_relations
  has_many :res_prod_relations
  has_many :station_service_relations
  has_many :order_prod_relations
  has_many :pcard_prod_relations
  has_many :prod_mat_relations
  has_many :materials, :through => :prod_mat_relations
  has_many :svcard_prod_relations
  has_many :image_urls
  has_many :stations, :through => :station_service_relations
  belongs_to :store
  has_one :category
  PRODUCT_TYPES = {0 => "清洁用品", 1 => "美容用品", 2 => "装饰产品", 3 => "配件产品", 4 => "电子产品",5 =>"其他产品",
    6 => "清洗服务", 7 => "维修服务", 8 => "钣喷服务", 9 => "美容服务", 10 => "安装服务", 11 => "其他服务"} #产品类别
  TYPES_NAME = {:CLEAN_PROD => 0, :BEAUTIFY_PROD => 1, :DECORATE_PROD => 2, :ASSISTANT_PROD => 3,
    :ELEC_PROD => 4,:OTHER_PROD => 5, :OTHER_SERV => 11}
  PRODUCT_END = 6
  BEAUTY_SERVICE = 9
  PROD_TYPES = {:PRODUCT =>0, :SERVICE =>1}  #0 为产品 1 为服务
  IS_VALIDATE ={:NO =>0,:YES =>1} #0 无效 已删除状态 1 有效   是否在pad上显示 0为不显示 1为显示
  SHOW_ON_IPAD ={:NO=>0,:YES=>1} #是否在ipad端显示
  REVIST_TIME = [24,48,72,96,120]
  IS_AUTO = {:YES=>1,:NO=>0}
  IS_ADDED = {:YES =>1,:NO=>0} # 是否需要施工
  SINGLE_TYPE = {:SIN =>0,:DOUB =>1} #单次服务0 套装 1
  #scope :is_service, joins(:categories).where("categories.types = ?", Category::TYPES[:service])
  scope :is_service, where(:is_service => true)
  scope :is_normal, where(:status => true)
  scope :commonly_used, where(:commonly_used => true)
  scope :on_weixin, lambda{|store_id| where(:store_id => store_id,:on_weixin => true,:status => true)}
  PACK_SERVIE  = {0=>"产品套装服务"}
  NEED_WORK = {-1=>"待施工产品"}
  WORK = {:WORK=>-1}
  PACK ={:PACK => 0}


end

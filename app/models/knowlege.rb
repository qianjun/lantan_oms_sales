#encoding: utf-8
class Knowlege < ActiveRecord::Base
  belongs_to :knowledge_type
  scope :on_weixin,where(:on_weixin => true)

  def self.load_know(store_id,types)
    self.joins(:knowledge_type).where(:knowledge_type_id => types,:store_id => store_id,:on_weixin => true).select("*")
  end
end

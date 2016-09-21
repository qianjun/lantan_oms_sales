#encoding: utf-8
class KnowledgeType < ActiveRecord::Base
  has_many :knowlege


  def self.load_btn(store_id)
    self.where(:store_id => store_id)
  end
  
end

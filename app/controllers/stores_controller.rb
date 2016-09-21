#encoding: utf-8
class StoresController < ApplicationController #活动页
  before_filter :set_title


  def index

    @stores = Store.where(:id=>params[:id])
    @products = Product.where(:store_id=>params[:id]).is_normal.commonly_used.group_by{|i|i.store_id}
  end

  def show
    @store = Store.find params[:id]
    @sales = Sale.on_weixin(@store.id).valid
    @staffs = Staff.where(:store_id=>params[:id],:status=>Staff::VALID_STATUS,:type_of_w=>Staff::S_COMPANY[:FRONT]).select("photo,phone,name")
    @products  = Product.on_weixin(@store.id).where(:id => @store.recommand_prods.split(",")).select("id,img_url,name,description, 2 types") if @store.recommand_prods

  end

  def set_title
    @title= "门店信息"
  end

  def tel_info
    @staffs = Staff.where(:store_id=>params[:store_id],:status=>Staff::VALID_STATUS,:type_of_w=>Staff::S_COMPANY[:FRONT])
    @departs = Department.where(:store_id=>params[:store_id],:id=>@staffs.map(&:position).compact).inject({}){|h,d|h[d.id]=d.name;h}
  end

  def store_map
    @store =Store.find params[:store_id]
    render :layout=>nil
  end

  def bind_user
    @store = Store.find params[:id]
  end

  def knowledge_show
    @types = KnowledgeType.where(:store_id => params[:id]).inject({}){|h,k|h["#{k.id}"] = k.name;h}
    @knows = Knowlege.load_know(params[:id],params[:types])
  end


end
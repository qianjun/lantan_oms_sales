#encoding: utf-8
class ItemsController < ApplicationController #活动页
  before_filter :set_title


  def show
    
    if @id == 1
      @prods = Product.is_normal.on_weixin(params[:store_id]).where(:is_service=>Product::PROD_TYPES[:PRODUCT]).select("id,img_url,name,description,0 types")
    elsif @id == 2
      @prods = Product.is_normal.is_service.on_weixin(params[:store_id]).select("id,img_url,name,description, 1 types")
    elsif @id == 3
      @prods = SvCard.on_weixin(params[:store_id]).normal_included(params[:store_id]).select("id,img_url,name,description, 4 types")
      @prods  <<  PackageCard.is_normal.on_weixin(params[:store_id]).select("id,img_url,name,description, 2 types")
    else @id == 4
      @store = Store.find  params[:store_id]
      @prods = Product.is_normal.on_weixin(params[:store_id]).where(:id => @store.recommand_prods.split(",")).select("id,img_url,name,description,0 types")
    end
  end

  def prod_detail
    types = (params[:types] ||= 0).to_i
    customer = Customer.where(:openid => params[:openid],:store_id => params[:store_id]).first
    @cat_num = Cart.where(:customer_id =>customer.id,:store_id =>params[:store_id] ).count()
    if types == 0 || types == 1
      @product = Product.where(:id=>params[:id]).select("sale_price,base_price,img_url,name,description,introduction,id").first
      @saled_num = OrderProdRelation.where(:product_id => @product.id ).sum("pro_num")
    elsif types == 4
      @product = SvCard.where(:id=>params[:id]).select("price sale_price,price base_price,img_url,name,description,id").first
      @saled_num = CSvcRelation.where(:sv_card_id =>@product.id ).count("*")
    elsif types == 2
      @product = PackageCard.where(:id=>params[:id]).select("price sale_price,price base_price,img_url,name,description,id").first
      @saled_num = CpcardRelation.where(:package_card_id =>@product.id ).count("*")
    end
  end



  def station_spot
   

  end

  private

  def set_title
    @title = Store.find(params[:store_id]).name
    @id = (params[:id] ||= 1).to_i
    @store = params[:store_id] ||= STORE_ID
  end



end
#encoding: utf-8
class CartsController < ApplicationController
  before_filter :binded?,:except=>["destroy"]

  def  index
    customer = Customer.where(:openid => params[:openid],:store_id => params[:store_id]).first
    @carts = {}
    Cart.normal.where(:store_id => params[:store_id],:customer_id => customer.id).group_by{|i|i.target_types}.each{|k,v|
      Cart::TYPES.each{|m,n| @carts[k]= eval(m).where(:id=>v.map(&:target_id)) if n.include? k}
    }
    @car_nums = CarNum.where(:id => CustomerNumRelation.where(:customer_id => customer.id).map(&:car_num_id))
    @cart_num = Cart.where(:store_id => params[:store_id],:customer_id => customer.id).inject({}){|h,c|h["#{c.target_types}_#{c.target_id}"] = c.target_num;h}
  end

  def create
    begin
      status = 0
      Cart.transaction do
        target = params[:target]
        customer = Customer.where(:openid => params[:openid],:store_id => target[:store_id]).first
        cart = Cart.where(:target_id => target[:target_id],:store_id => target[:store_id],
          :customer_id => customer.id,:status=>Cart::STATUS[:NORMAL],:target_types => params[:target_types]).first
        if  customer.nil?
          status = 1
        elsif cart.nil?
          Cart.create(target.merge(:customer_id => customer.id))
        else
          cart.update_attribute(:target_num,cart.target_num+1)
        end
      end
    rescue
      status = 2
    end
    render :json => {:status => status,:types => params[:btn_types],:openid =>params[:openid],:store_id => params[:store_id]}
  end

  def destroy
    begin
      status = 0
      Cart.transaction do
        customer = Customer.where(:openid => params[:openid],:store_id => params[:store_id]).first
        params[:del_prods].each { |k,v| Cart.where(:target_types =>k,:target_id =>v,:customer_id => customer.id).update_all(:status =>Cart::STATUS[:USED])}
      end
    rescue
      status = 1
    end
    render :json => {:status => status}
  end
end

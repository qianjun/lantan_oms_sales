#encoding: utf-8
class CustomersController < ApplicationController #活动页


  def create
    customer = Customer.search_self(params[:openid],params[:store_id])
    if customer
      redirect_to "/stores/#{params[:store_id]}/customers/#{params[:openid]}"
    else
      car_num = CarNum.where(:num => params[:car_num]).first
      if car_num
        customer = Customer.where(:mobilephone => params[:phone],:id=>car_num.customer_num_relation.customer_id,:store_id => params[:store_id]).first
        if customer
          customer.update_attributes(:openid => params[:openid])
          redirect_to "/stores/#{params[:store_id]}/customers/#{params[:openid]}"
        else
          redirect_to request.referer
        end
      else
        redirect_to request.referer
      end
    end
  end

  def show
    @customer = Customer.search_self(params[:id],params[:store_id])
    p @car_nums = CustomerNumRelation.joins(:car_num).where(:customer_id=>@customer.id).select("*").map(&:num)
    
  end
end
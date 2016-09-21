#encoding: utf-8
class CustomersController < ApplicationController #活动页


  def create
    if Customer.find_by_openid(params[:openid])
      car_num = CarNum.where(:num => params[:car_num]).first
      if car_num
        customer = Customer.where(:mobilephone => params[:phone],:id=>car_num.customer_num_relation.customer_id).first
        if customer
          customer.update_attributes(:openid => params[:openid])
          redirect_to customers_path(customer)
        end
      end
      redirect_to customers_path(customer)
    end
  end

  def show
    
  end
end
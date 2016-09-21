#encoding: utf-8
class OrdersController < ApplicationController
  before_filter :binded?,:except=>["create"]
  
  def index
    customer = Customer.where(:openid => params[:openid],:store_id => params[:store_id]).first
    time_sql = "date_format(created_at,'%Y-%m-%d') > #{(Time.now-90.days).strftime('%Y-%m-%d')}"
    p @reservs = Reservation.where(:customer_id => customer.id,:store_id => params[:store_id],
      :status =>Reservation::STATUS[:normal] ).where(time_sql).select("*,target_num*target_price sum")
    @car_nums = CarNum.where(:id => @reservs.map(&:car_num_id)).inject({}){|h,c|h[c.id]=c.num;h}
  end

  def operate_process
    customer = Customer.where(:openid => params[:openid],:store_id => params[:store_id]).first
    @work_orders = WorkOrder.joins(:order).where(:"work_orders.status" => WorkOrder::NO_END,:orders=>{:customer_id => customer.id,
        :store_id=> params[:store_id]}).today.select("car_num_id,order_id,work_orders.status,
      (unix_timestamp(work_orders.ended_at)-unix_timestamp(now()))/60 cost_time").group_by{|i|i.car_num_id}
    @products = OrderProdRelation.joins(:product).where(:order_id =>@work_orders.values.flatten.map(&:order_id)).select("order_id,name,cost_time").inject({}){|h,p|h[p.order_id]=p;h}
    @car_nums = CarNum.where(:id=>@work_orders.keys)
  end

  def other_info
    customer = Customer.where(:openid => params[:openid],:store_id => params[:store_id]).first
    @car_nums = CustomerNumRelation.joins(:car_num).where(:customer_id => customer.id).select("car_nums.num")
    @pcards = CPcardRelation.where(:customer_id => customer.id,:status =>CPcardRelation::STATUS[:NORMAL]).
      select("content,0 types,package_card_id card_id").inject({}){|h,c|h[c.card_id] ||= {};
      c.content.split(",").each{|cc|lc =cc.split("-");h[c.card_id][lc[1]] ||=0;h[c.card_id][lc[1]]+= lc[2].to_i }  if c.content;h}
    @c_cards = CSvcRelation.where(:customer_id => customer.id,:status =>CSvcRelation::STATUS[:valid]).
      select("sum(total_price) t_price,sum(left_price) l_price,sv_card_id,1 types").group("sv_card_id")
    @p_cards = PackageCard.where(:id => @pcards.keys).select("id,name,0 types")
    @sv_cards = SvCard.where(:id => @c_cards.map(&:sv_card_id)).select("id,name,1 types")
    @show = @p_cards[0] || @sv_cards[0]
  end

  def create
    customer = Customer.where(:openid => params[:openid],:store_id => params[:store_id]).first
    status = 1
    begin
      Reservation.transaction do
        params[:submit_prods].each do |type,target_ids|
          target_price = {}
          Cart::TYPES.each{|m,n| target_price = eval(m).where(:id => target_ids).inject({}){|h,item|
              h[item.id]= item.attributes["sale_price"] || item.attributes["price"];h} if n.include? type.to_i}
          target_ids.each do |target_id|
            Reservation.create(:code=>Reservation.generate_code(params[:store_id]),:customer_id=> customer.id,
              :car_num_id => params[:car_num_id],:status=>Reservation::STATUS[:normal],:store_id=>params[:store_id],
              :prod_id =>target_id,:res_time=>Time.now,:types=>Reservation::TYPES[:RESER],:prod_types=>type,:prod_price => target_price[target_id.to_i],
              :prod_num =>params[:subit_num][:"#{type}_#{target_id}"])
          end
          Cart.where(:target_types =>type,:target_id =>target_ids,:customer_id => customer.id).update_all(:status =>Cart::STATUS[:USED])
        end
        status = 0
      end
    rescue
    end
    render :json => {:status => status}
    
  end

end

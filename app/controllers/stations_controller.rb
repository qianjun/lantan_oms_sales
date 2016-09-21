#encoding: utf-8
class StationsController < ApplicationController

  def index
    @customer = Customer.where(:store_id => params[:store_id], :openid => params[:openid]).first
    @stations = Station.normal.this_store(params[:store_id])
    p @work_orders = WorkOrder.serving.today.inject({}){|h,w|h[w.station_id]=w.station_id;h}
    @station_lines = OrderProdRelation.joins(" inner join  orders o on o.id = order_prod_relations.order_id inner join
    station_service_relations sr on sr.product_id = order_prod_relations.product_id").
      where(:order_id => WorkOrder.wait.today.this_store(params[:store_id]).map(&:order_id)).
      select("sr.station_id s_id,count(*) num").group("sr.station_id").inject({}){|h,s|h[s.s_id]=s.num;h}
  end

end

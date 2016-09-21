#encoding: utf-8
class WorkOrder < ActiveRecord::Base
  belongs_to :station
  belongs_to :order
  belongs_to :store
  STATUS = {0=>"等待服务中",1=>"服务中",2=>"等待付款",3=>"已完成", 4 => "已取消", 5 => "已终止"}
  STAT = {:WAIT => 0,:SERVICING => 1,:WAIT_PAY => 2,:COMPLETE => 3, :CANCELED => 4, :END => 5}
  NO_END = [STAT[:WAIT],STAT[:SERVICING]]
  scope :wait,where(:status => STAT[:WAIT])
  scope :this_store,lambda{|store_id|where(:store_id=>store_id)}
  scope :today,where(:current_day => Time.now.strftime("%Y%m%d").to_i)
  scope :serving,where(:status => STAT[:SERVICING])

  def self.update_work_order(parms)
    message,dir = "ok","#{Rails.root}/public/logs"
    Dir.mkdir(dir)  unless File.directory?(dir)
    file_path = dir+"/returnBack_#{Time.now.strftime("%Y%m%d")}.log"
    if File.exists? file_path
      file = File.open( file_path,"a")
    else
      file = File.new(file_path, "w")
    end
    file.puts "#{Time.now.strftime('%Y%m%d %H:%M:%S')}   #{parms}\r\n"
    begin
      current_day,store,num = Time.now.strftime("%Y%m%d"),Store.find_by_code(parms[:shop]),parms[:id].to_i 
      if store
        station = Station.where(:code=>parms[:work]).where(:store_id=>store.id).first
        if station && station.is_has_controller
          equipment_info = EquipmentInfo.where("current_day = #{current_day.to_i} and station_id=#{station.id}
                       and store_id=#{store.id}").first
          if  (equipment_info.nil? || num != equipment_info.num )
            work_order = WorkOrder.where("status = #{WorkOrder::STAT[:SERVICING]} and station_id = #{station.id} and
                         current_day = #{current_day} and store_id = #{station.store_id}").first
            if work_order
              water_num = parms[:name12].to_f*10**4 + parms[:name2].to_f
              gas_num = parms[:name13].to_f*10**4+parms[:name3].to_f
              order = work_order.order
              unless work_order.status ==  WorkOrder::STAT[:CANCELED]
                staffs = [order.try(:cons_staff_id_1), order.try(:cons_staff_id_2)]
                w_records = WorkRecord.where(:staff_id => (staffs | [order.try(:cons_staff_id_1)]).compact,:current_day=>Time.now.strftime("%Y-%m-%d"))
                w_records.each {|w_record|
                  g_num = w_record.gas_num.nil? ? 0 : w_record.gas_num
                  w_num = w_record.water_num.nil? ? 0 : w_record.water_num
                  water_num = water_num.nil? ? 0 : water_num/2.0
                  gas_num =  gas_num.nil? ? 0 : gas_num/2.0
                  w_record.update_attributes(:water_num=>w_num+water_num,:gas_num=>g_num+gas_num)} unless w_records.blank?
              end
              if equipment_info.nil?
                EquipmentInfo.create(:current_day => current_day.to_i, :num =>num,:store_id=>store.id,:station_id=>station.id)
              else
                equipment_info.update_attribute(:num,num)
              end
            end
          end
        end
      end
    rescue => error
      file.puts "#{error}\r\n"
    end
    file.close
    return message
  end

  def arrange_station(gas_num=nil,water_num=nil,stop=false)
    current_time = Time.now
    #把完成的单的状态置为等待付款
    order = self.order
    Order.transaction do
      unless stop
        unless self.status ==  WorkOrder::STAT[:CANCELED]
          runtime = sprintf('%.2f',(current_time - self.started_at)/60).to_f
          status = (order.status == Order::STATUS[:BEEN_PAYMENT] || order.status == Order::STATUS[:FINISHED]) ? WorkOrder::STAT[:COMPLETE] : WorkOrder::STAT[:WAIT_PAY]
          self.update_attributes(:status => status, :runtime => runtime,:water_num => water_num, :gas_num => gas_num)
          staffs = TechOrder.where(:order_id=>order.id).map(&:staff_id)
          w_records = WorkRecord.where(:staff_id => (staffs | [order.try(:front_staff_id)]).compact,:current_day=>Time.now.strftime("%Y-%m-%d"))
          w_records.each {|w_record|
            c_num = w_record.construct_num.nil? ? 0 : w_record.construct_num
            g_num = w_record.gas_num.nil? ? 0 : w_record.gas_num
            w_num = w_record.water_num.nil? ? 0 : w_record.water_num
            water_num = water_num.nil? ? 0 : water_num*1.0/w_records.length
            gas_num =  gas_num.nil? ? 0 : gas_num*1.0/w_records.length
            w_record.update_attributes(:construct_num=>c_num+1,:water_num=>w_num+water_num,:gas_num=>g_num+gas_num)} unless w_records.blank?
        end
        order.update_attribute(:status, Order::STATUS[:WAIT_PAYMENT]) if order.status != Order::STATUS[:BEEN_PAYMENT] && order.status != Order::STATUS[:FINISHED] && order.status != Order::STATUS[:RETURN]
      end

      orders = Order.includes(:work_orders).where("work_orders.status = #{WorkOrder::STAT[:SERVICING]}").
        where("work_orders.current_day = #{Time.now.strftime("%Y%m%d")}").
        where("work_orders.store_id = #{self.store_id}") #[1341,1344,1354,1356,1357,1360]
      car_num_id_sql = orders.length == 0 ? '1=1' : "orders.car_num_id not in (?)"
      t_station_staffs = StationStaffRelation.where(:current_day=>Time.now.strftime("%Y%m%d")).group_by{|i|i.station_id}
      #排下一个单
      next_work_order = WorkOrder.where("status = #{WorkOrder::STAT[:WAIT]}").where(:station_id => self.station_id).
        where("store_id = #{self.store_id}").where("current_day = #{self.current_day}").first
      if next_work_order
        #同一个人的下单，直接紧接着排单
        time = next_work_order.cost_time.nil? ? 0 : next_work_order.cost_time
        ended_at = current_time + time*60
        next_work_order.update_attributes(:status => WorkOrder::STAT[:SERVICING],
          :started_at => current_time, :ended_at => ended_at )
        wo_time = WkOrTime.find_by_station_id_and_current_day next_work_order.station_id, ended_at
        wo_time.update_attribute(:wait_num, wo_time.wait_num - 1) if wo_time and wo_time.wait_num
        next_order = next_work_order.order
        next_order.update_attribute(:status, Order::STATUS[:SERVICING]) if next_order && next_order.status != Order::STATUS[:BEEN_PAYMENT] && next_order.status != Order::STATUS[:FINISHED]
        message = "has_next_work_order"
      else
        #按照created_at时间来排单
        products = StationServiceRelation.where(:station_id=>self.station_id).map(&:product_id)
        #qualified_station_arr = Station.return_station_arr(products, self.store_id)[0]
        another_work_orders = WorkOrder.joins(:order).where("work_orders.status = #{WorkOrder::STAT[:WAIT]}").
          where("work_orders.station_id is null and work_orders.store_id = #{self.store_id}").
          where("work_orders.current_day = #{self.current_day}").where(car_num_id_sql,orders.map(&:car_num_id)).
          readonly(false).order("work_orders.created_at asc")
        order_product_ids = OrderProdRelation.joins(:product).where(:order_id => another_work_orders.map(&:order_id),
          :products => {:is_service => Product::PROD_TYPES[:SERVICE]}).group_by{|i|i.order_id}
        if_wo_set_station,same_car_num_id = false,nil
        tech_orders = TechOrder.where(:order_id=> another_work_orders.map(&:order_id)).group_by{|i|i.order_id}
        another_work_orders.each do |another_work_order|
          #      if another_work_orders.length >= 1
          another_order = another_work_order.order
          product_ids = order_product_ids[another_order.id].nil? ? [] : order_product_ids[another_order.id].map(&:product_id)
          if (products & product_ids).sort == product_ids.sort
            if if_wo_set_station   #将第一辆车排进当前工位
              if same_car_num_id == another_work_order.order.car_num_id #已排单 将相同车辆的可以在本工位施工的工单更新工位状态
                another_work_order.update_attributes(:station_id => self.station_id)
                update_tech(another_order,self.station_id,t_station_staffs,tech_orders) #更新提成的技师
              end
            else
              ended_at = current_time + another_work_order.cost_time*60
              another_work_order.update_attributes(:status => WorkOrder::STAT[:SERVICING], :started_at => current_time, :ended_at => ended_at, :station_id => self.station_id)
              update_tech(another_order,self.station_id,t_station_staffs,tech_orders) #更新提成的技师
              same_car_num_id  = another_order.car_num_id
              if_wo_set_station = true
              another_order.update_attributes(:status => Order::STATUS[:SERVICING])  if another_order && another_order.status != Order::STATUS[:BEEN_PAYMENT] && another_order.status != Order::STATUS[:FINISHED]
            end
          end

        end unless another_work_orders.blank? or self.station.locked

        #同一个car_num_id，当符合条件的工位为空时，排单
        same_work_orders = WorkOrder.joins(:order).
          where("work_orders.station_id is null").
          where("work_orders.status = #{WorkOrder::STAT[:WAIT]}").
          where("orders.car_num_id = #{order.car_num_id}").
          where("work_orders.store_id = #{self.store_id}").
          where("work_orders.current_day = #{self.current_day}").readonly(false).order("work_orders.created_at asc")
        if same_work_orders.any? && next_work_order.nil?
          first_station_id = nil
          tech_orders = TechOrder.where(:order_id=> same_work_orders.map(&:order_id)).group_by{|i|i.order_id}
          p_ids = OrderProdRelation.where(:order_id=>same_work_orders.map(&:order_id)).group_by{|i|i.order_id}
          same_work_orders.each_with_index do |same_work_order, index|
            product_ids = p_ids[same_work_order.order_id].map(&:product_id)
            infos = Station.return_station_arr(product_ids, same_work_order.store_id)
            station_arr = infos[0].map(&:id)
            wkor_times = WorkOrder.where(:station_id => station_arr, :current_day => Time.now.strftime("%Y%m%d"),
              :store_id =>self.store_id, :status => [WorkOrder::STAT[:WAIT], WorkOrder::STAT[:SERVICING]]).map(&:station_id).uniq
            if station_arr.any? and (wkor_times.blank? or (station_arr & wkor_times != station_arr) )
              leave_station_id = (station_arr - wkor_times)[0]
              same_order = same_work_order.order
              if index == 0
                first_station_id = leave_station_id
                s_ended_at = Time.now + same_work_order.cost_time*60
                if_wo_set_station = true
                same_work_order.update_attributes(:status => WorkOrder::STAT[:SERVICING], :station_id => leave_station_id,
                  :started_at => Time.now, :ended_at => s_ended_at)
                update_tech(same_order,leave_station_id,t_station_staffs,tech_orders) #更新提成的技师
                same_order.update_attributes(:status => Order::STATUS[:SERVICING]) if same_order && same_order.status != Order::STATUS[:BEEN_PAYMENT] && same_order.status != Order::STATUS[:FINISHED]
                wk_or_time = WkOrTime.find_by_station_id_and_current_day leave_station_id, Time.now.strftime("%Y%m%d").to_i
                WkOrTime.create(:current_day => Time.now.strftime("%Y%m%d").to_i, :station_id => leave_station_id,
                  :current_times => s_ended_at.strftime("%Y%m%d%H%M")) unless wk_or_time
              else
                if first_station_id and station_arr.include?(first_station_id) #如果其他服务也可以用到这个工位
                  same_work_order.update_attribute(:station_id, first_station_id)
                  update_tech(same_order,first_station_id,t_station_staffs,tech_orders) #更新提成的技师
                end
              end
            end
          end
        end

        #        diff_work_order = WorkOrder.where("status = #{WorkOrder::STAT[:WAIT]}").
        #          where("station_id is not null and store_id = #{self.store_id} and current_day = #{self.current_day}").first
        #        serving_work_orders = WorkOrder.where(:status => WorkOrder::STAT[:SERVICING],:store_id =>self.store_id,:current_day =>self.current_day)
        #        if diff_work_order && !if_wo_set_station
        #          next_station_id =  diff_work_order.station_id
        #          next_order = diff_work_order.order
        #          this_car_num_id = next_order.car_num_id
        #          if !orders.map(&:car_num_id).compact.include?(this_car_num_id) && !serving_work_orders.map(&:station_id).include?(next_station_id)
        #            s_ended_at = Time.now + diff_work_order.cost_time*60
        #            diff_work_order.update_attributes(:status => WorkOrder::STAT[:SERVICING], :station_id =>next_station_id,
        #              :started_at => Time.now, :ended_at => s_ended_at)
        #            t_station_staffs[next_station_id].map(&:staff_id).each_with_index do |staff_id,index|
        #              tech_orders[next_order.id][index].update_attributes(:staff_id=>staff_id)
        #            end  if next_order
        #            if next_order && next_order.status != Order::STATUS[:BEEN_PAYMENT] && next_order.status != Order::STATUS[:FINISHED]
        #              next_order.update_attributes(:status => Order::STATUS[:SERVICING], :station_id =>next_station_id)
        #            end
        #            wk_or_time = WkOrTime.find_by_station_id_and_current_day next_station_id, Time.now.strftime("%Y%m%d").to_i
        #            WkOrTime.create(:current_day => Time.now.strftime("%Y%m%d").to_i, :station_id =>next_station_id,
        #              :current_times => s_ended_at.strftime("%Y%m%d%H%M")) unless wk_or_time
        #          end
        #        end
      end
      message
    end
  end

  def update_tech(order,station_id,t_station_staffs,tech_orders)
    t_station_staffs[station_id].map(&:staff_id).each_with_index do |staff_id,index|
      tech_orders[order.id][index].update_attributes(:staff_id=>staff_id)
    end if station_id and order and t_station_staffs[station_id]
  end
  
end

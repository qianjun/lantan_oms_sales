#encoding: utf-8
class Station < ActiveRecord::Base
  has_many :word_orders
  has_many :station_staff_relations
  has_many :staffs, :through => :station_staff_relations
  has_many :station_service_relations
  has_many :wk_or_times
  has_many :products, :through => :station_service_relations
  belongs_to :store
  has_many :equipment_infos
  STAT = {:WRONG =>0,:LACK =>1,:NORMAL =>2,:NO_SERVICE =>3, :DELETED => 4} #0 故障 1 缺少技师 2 正常 3 无服务
  STAT_NAME = {0=>"故障",1=>"缺少技师",2=>"正常",3=>"缺少服务项目"}
  VALID_STATUS = [STAT[:WRONG], STAT[:NORMAL], STAT[:LACK], STAT[:NO_SERVICE]]
  scope :is_normal,lambda{|store_id| where(:store_id => store_id,:status=>[STAT[:NORMAL], STAT[:LACK], STAT[:NO_SERVICE]])}
  scope :can_show, where(:status => VALID_STATUS)
  scope :this_store,lambda{|store_id|where(:store_id=>store_id)}
  scope  :normal,where(:status => STAT[:NORMAL])
  LOCK = {:NO=>0,:YES=>1}
  scope :no_locked,where(:locked=>LOCK[:NO])
  IS_CONTROLLER = {:YES=>1,:NO=>0} #定义是否拥有工控机
  PerPage = 10
  validates :name, :presence => true

  validate :unique_code

  def unique_code
    station = Station.where("store_id = ? and status != ? and code = ?", store_id, STAT[:DELETED], code).first
    if (station && station.id != self.id)
      errors.add(:code, "工位编号在当前门店中已经存在")
    end
  end
  # validates :code, uniqueness: { scope: :store_id, message: "工位编号在当前门店中已经存在！" }, :if => :has_no_existed_code
  
  scope :valid, where("status != 4")
  
  def self.set_stations(store_id)
    s_levels ={}  #所需技师等级
    l_staffs ={}  #现有等级的技师
    next_turn=[]
    stations=Station.where("store_id=#{store_id} and status != #{Station::STAT[:WRONG]} and status !=#{Station::STAT[:DELETED]}")
    stations.each do |station|
      prod=Product.find_by_sql("select staff_level level1,staff_level_1 level2 from products p inner join station_service_relations  s on
      s.product_id=p.id where s.station_id=#{station.id}").inject(Array.new) {|sum,level| sum.push(level.level1,level.level2)}.compact.uniq.sort
      unless prod.blank?
        s_levels[station.id]=[prod[0..(prod.length/2.0-0.5)].max,prod.max]
      else
        Station.find(station.id).update_attributes(:status=>Station::STAT[:NO_SERVICE])
      end
    end
    Staff.find_by_sql("select name,id,level from staffs where store_id=#{store_id} and type_of_w=#{Staff::S_COMPANY[:TECHNICIAN]} and status=#{Staff::STATUS[:normal]}").each {|staff|
      if l_staffs[staff.level]
        l_staffs[staff.level].push([staff.id,staff.name])
      else
        l_staffs[staff.level]=[[staff.id,staff.name]]
      end
    }
    s_levels.each do |station,level|
      level.each_with_index do |k,index|
        if l_staffs[k].nil? || l_staffs[k].shuffle[0].nil?
          s_levels[station][index] = nil
          next_turn << [k,station,index]
        else
          s_levels[station][index] = l_staffs[k].delete(l_staffs[k].shuffle[0])
        end
      end
    end
    stills=l_staffs.delete_if {|key, value| value==[] }
    next_turn.sort_by { |turn| turn[0]  }.reverse.each {|turn|
      level_values = []  #符合条件的staff
      unless stills.select {|k,v| k >  turn[0] }.empty?
        stills.select {|k,v| k > turn[0] }.each_pair {|key,value| value.each {|val| level_values.push(val.push(key))} }
        #筛选合格的staff并记录等级
        selected_staff = level_values.shuffle[0]   #随机选取staff
        index = selected_staff.delete_at(-1)
        stills[index].delete(selected_staff)      #已选择的staff删除
        s_levels[turn[1]][turn[2]] = selected_staff   #安排staff进工位
        stills=stills.delete_if {|key, value| value == [] }
        stills.select {|k,v| k > turn[0] }.each {|key,value| value.each {|val| val.delete_at(-1)}}
        # 相应等级无staff的删除  并将符合筛选条件但没选中的staff 删除等级
      end
    }
    StationStaffRelation.find_all_by_current_day(Time.now.strftime("%Y%m%d")).each {|station| station.destroy}
    s_levels.each  {|station_id,staffs|
      if staffs.include?(nil)
        Station.find(station_id).update_attributes(:status=>Station::STAT[:LACK])
      else
        Station.find(station_id).update_attributes(:status=>Station::STAT[:NORMAL])
      end
      staffs.each {|staff|
        if staff
          StationStaffRelation.create(:station_id=>station_id,:staff_id=>staff[0],:current_day=>Time.now.strftime("%Y%m%d"),:store_id=>store_id)
        end
      }
    }
  end

  #工位安排技师 h_staff 员工id h_level 技师等级
  def self.set_station(store_id,h_staff,h_level)
    s_levels ={}  #所需技师等级
    o_staffs = {}  #已分配技师的工位
    o_tech =[] #已分配工位的技师
    t_staffs ={}
    StationStaffRelation.joins(:staff).where("current_day=#{Time.now.strftime("%Y%m%d").to_i} and station_staff_relations.store_id=#{store_id}").select("staffs.level,station_staff_relations.*").each{
      |staff|o_tech << staff.staff_id;o_staffs[staff.station_id].nil? ? o_staffs[staff.station_id] = staff.level : o_staffs.delete(staff.station_id);
      t_staffs[staff.station_id].nil? ? t_staffs[staff.station_id] = [staff.level] : t_staffs[staff.station_id] << staff.level}
    unless o_tech.include? h_staff  #如果该员工已分配工位则不再分配
      stations=Station.where("store_id=#{store_id} and status != #{Station::STAT[:WRONG]} and status !=#{Station::STAT[:DELETED]}")
      stations.each do |station|
        if station.staff_level  #兼容老数据，当工位没有服务等级的时候自动修改工位的等级
          if t_staffs[station.id].nil? #该工位未分配技师时
            s_levels[station.staff_level].nil? ? s_levels[station.staff_level]=[station.id] : s_levels[station.staff_level] << station.id
            s_levels[station.staff_level1].nil? ? s_levels[station.staff_level1]=[station.id] : s_levels[station.staff_level1] << station.id
          elsif o_staffs[station.id] #如果已分配技师则判断是否只有一个，o_staffs存在的话就证明只分配了一个
            levels = [station.staff_level] | [station.staff_level1]
            if levels.length==1 && o_staffs[station.id] #当工位要求的技师等级相同且已经分配时
              s_levels[station.staff_level].nil? ? s_levels[station.staff_level]=[station.id] : s_levels[station.staff_level] << station.id
            elsif levels.length==2
              if levels.include? o_staffs[station.id]  #如果已分配的技师和其中的一个等级一致
                levels.delete(o_staffs[station.id])
                s_levels[levels[0]].nil? ? s_levels[levels[0]]=[station.id] : s_levels[levels[0]] << station.id
              else
                if levels.min > o_staffs[station.id]  #所需最高级技师小于当前技师等级时则覆盖最高技师，将所需低级工位
                  s_levels[levels.max].nil? ? s_levels[levels.max]=[station.id] : s_levels[levels.max] << station.id
                else  #如果无法覆盖则意味着能够覆盖低级工位，将高级的去分配
                  s_levels[levels.min].nil? ? s_levels[levels.min]=[station.id] : s_levels[levels.min] << station.id
                end
              end
            end
          end
        else
          prod=Product.find_by_sql("select staff_level level1,staff_level_1 level2 from products p inner join station_service_relations  s on
      s.product_id=p.id where s.station_id=#{station.id} and p.status=#{Product::IS_VALIDATE[:YES]}").inject(Array.new) {|sum,level| sum.push(level.level1,level.level2)}.compact.uniq.sort
          unless prod.blank?
            Station.find(station.id).update_attributes(:staff_level=>prod.min,:staff_level1=>prod[0..(prod.length/2.0)].max)
          else
            Station.find(station.id).update_attributes(:status=>Station::STAT[:NO_SERVICE])
          end
        end
      end
      s_levels.each_pair { |key,value| s_levels[key]=value.uniq.sort }
      if s_levels[h_level].nil? || s_levels[h_level].blank? #没有合适的工位级别或者改级别工位已分配完毕
        Staff::LEVELS.keys[(h_level+1)..Staff::LEVELS.keys.length].each do |level|
          if s_levels[level] && !s_levels[level].blank?
            h_level =  level
            break
          end
        end
      end
      if s_levels[h_level] && !s_levels[h_level].blank?
        if  o_staffs.keys.blank? #当工位都没有分配的时候
          StationStaffRelation.create(:station_id=>s_levels[h_level][0],:staff_id=>h_staff,:current_day=>Time.now.strftime("%Y%m%d"),:store_id=>store_id)
          Station.find(s_levels[h_level][0]).update_attributes(:status=>Station::STAT[:LACK])
        else #已分配的工位
          is_half = true
          s_levels[h_level].each{|station|
            if o_staffs.keys.include? station
              StationStaffRelation.create(:station_id=>station,:staff_id=>h_staff,:current_day=>Time.now.strftime("%Y%m%d"),:store_id=>store_id)
              Station.find(station).update_attributes(:status=>Station::STAT[:NORMAL])
              is_half = false
              break
            end
          }
          if  is_half  #已分配工位中不包含当前级别的技师
            StationStaffRelation.create(:station_id=>s_levels[h_level][0],:staff_id=>h_staff,:current_day=>Time.now.strftime("%Y%m%d"),:store_id=>store_id)
            Station.find(s_levels[h_level][0]).update_attributes(:status=>Station::STAT[:LACK])
          end
        end
      end
    end
  end

  def self.make_data(store_id)
    return  "select c.num,w.station_id,o.front_staff_id,w.status,w.order_id from work_orders w inner join orders o on 
    w.order_id=o.id inner join car_nums c on c.id=o.car_num_id where current_day='#{Time.now.strftime("%Y%m%d")}' and
    w.status in (#{WorkOrder::STAT[:SERVICING]},#{WorkOrder::STAT[:WAIT_PAY]},#{WorkOrder::STAT[:WAIT]}) and w.store_id=#{store_id}"
  end

  def self.ruby_to_js(hashs)
    return hashs.inect(Hash.new) {|hash,con|con.each{|k,v|  hash["#{k}"]="#{v}" };hash}.gsub("=>",":")
  end


  def self.filter_dir(store_id)
    path_dir = Constant::LOCAL_DIR
    dirs=["#{Constant::VIDEO_DIR}/","#{store_id}/"]
    dirs.each_with_index {|dir,index| Dir.mkdir path_dir+dirs[0..index].join   unless File.directory? path_dir+dirs[0..index].join }
    video_path ="/public/"+dirs.join
    paths= TechOrder.get_dir_list("#{Rails.root}"+video_path)
    video_hash ={}
    paths.each do |path|
      mtime =File.stat("#{Rails.root}"+video_path+path).mtime.strftime("%Y-%m-%d")
      if video_hash[mtime]
        video_hash[mtime] << "/#{(dirs.join+path).force_encoding("UTF-8")}"
      else
        video_hash[mtime] = ["/#{(dirs.join+path).force_encoding("UTF-8")}"]
      end
    end unless paths.blank?
    return video_hash
  end

  #返回满足条件的工位
  def self.return_station_arr(prod_ids, store_id)
    station_arr,station_prod_ids = [],[]
    prod_ids = prod_ids.collect{|p| p.to_i }
    station_id = StationStaffRelation.select("station_id").where(:current_day => Time.now.strftime("%Y%m%d").to_i,
      :store_id =>store_id).group("station_id").having("count(*)=2").map(&:station_id)
    prod_stations = StationServiceRelation.select("product_id,station_id").joins(:product).where(:station_id=>station_id).group_by{|i|i.station_id}
    Station.includes(:station_service_relations).where(:stations=>{:store_id => store_id,
        :status => Station::STAT[:NORMAL], :id => station_id}).no_locked.each do |station|
      if prod_stations && prod_stations[station.id].length > 0
        prods = prod_stations[station.id].map(&:product_id)  #找出每个工位支持的服务
        station_prod_ids << prods
        station_arr << station if (prods & prod_ids).sort == prod_ids.sort  #如果这个工位支持所有需要的服务
      end
    end
    return [station_arr, station_prod_ids]  #返回所有支持所需的服务的工位， 当前所有工位所支持的全部服务
  end


  def self.arrange_time store_id, prod_ids, order = nil, res_time = nil
    #查询所有满足条件的工位
    infos = self.return_station_arr(prod_ids, store_id)
    station_arr = infos[0]    #所有支持所需服务的工位
    station_prod_ids = infos[1] #当前所有工位所支持的全部服务
    if station_arr.present?
      station_flag = 1 #有对应工位对应
    else
      if((station_prod_ids.flatten & prod_ids).sort == prod_ids.sort) && (!station_prod_ids.include?(prod_ids))
        station_flag = 2 #一个订单要使用多个工位
      else
        station_flag = 0 #没工位
      end
    end
    
    station_id = 0
    has_start_end_time = false
    #如果用户连续多次下单并且购买的服务可以在原工位上施工，则排在原来工位上。
    if order
      work_order = WorkOrder.joins(:order).where(:orders => {:car_num_id => order.car_num_id},
        :work_orders => {:status => WorkOrder::STAT[:SERVICING], :store_id => store_id,
          :current_day => Time.now.strftime("%Y%m%d").to_i}).order("ended_at desc").first
      if work_order && station_arr.map(&:id).include?(work_order.station_id) #[1,3] 5  # 看看同一辆车之前在的工位能不能施工现在下单的服务
        station_id = work_order.station_id
      end
    end
    if station_id == 0
      #按照工位的忙闲获取预计时间     
      busy_stations = WorkOrder.where(:station_id => station_arr, :current_day => Time.now.strftime("%Y%m%d"),      
        :store_id =>store_id, :status => [WorkOrder::STAT[:WAIT], WorkOrder::STAT[:SERVICING]]).map(&:station_id)
      availbale_stations = station_arr.map(&:id) - busy_stations
      if availbale_stations.present? && (order.nil? ||work_order.nil? ) #如果是同一辆车，需要排在不同的工位上的话，不置station_id和开始结束时间
        station_id = availbale_stations[0] || 0
        has_start_end_time = true
      else
        station_id = nil
      end
    end
    [station_id, station_flag, has_start_end_time]
  end
  
  def self.turn_old_to_new
    work_records,total_con = [],[]
    StationStaffRelation.delete_all(:current_day=>Time.now.strftime("%Y%m%d"))
    WorkRecord.delete_all(:current_day=>Time.now.strftime("%Y-%m-%d"))
    stores = Store.where(:status=>Store::STATUS[:OPENED])
    infos = StationStaffRelation.where(:current_day=>[Time.now.strftime("%Y%m%d"),Time.now.yesterday.strftime("%Y%m%d")],:store_id=>stores.map(&:id)).group_by{
      |s| "#{s.current_day}_#{s.store_id}"}
    staffs = Staff.where(:status=>Staff::STATUS[:normal],:store_id=>stores.map(&:id))
    tech_staffs = staffs.group_by{|i|"#{i.type_of_w}_#{i.store_id}"}
    work_r_staffs = staffs.group_by{|i|i.store_id}
    stores.each do |store|
      today_info = infos["#{Time.now.strftime("%Y%m%d")}_#{store.id}"]
      yesterday_info = infos["#{Time.now.yesterday.strftime("%Y%m%d")}_#{store.id}"]
      if today_info.nil?
        if yesterday_info.nil?
          tech_staffs["#{Staff::S_COMPANY[:TECHNICIAN]}_#{store.id}"].each do |staff|
            Station.set_station(store.id,staff.id,staff.level)
          end unless tech_staffs["#{Staff::S_COMPANY[:TECHNICIAN]}_#{store.id}"].nil?
        else
          p "#{store.id}--#{yesterday_info.length}"
          yesterday_info.each {|info|
            total_con << StationStaffRelation.new({:station_id=>info.station_id,:staff_id=>info.staff_id,:current_day=>Time.now.strftime("%Y%m%d"),:store_id=>store.id})
          }
        end
      end   #自动分配技师
      work_r_staffs[store.id].each do |staff|   #生成员工记录
        work_records << WorkRecord.new({:current_day=>Time.now.strftime("%Y-%m-%d"),:attendance_num=>1,:staff_id=>staff.id,:store_id=>store.id})
      end unless work_r_staffs[store.id].nil?
    end
    WorkRecord.import work_records, :timestamps=>true unless work_records.blank?
    StationStaffRelation.import total_con, :timestamps=>true unless total_con.blank?
  end

  #根据，订单，工位，门店id排空工位 arrange 0 station_id 2 status 1 flag
  def self.create_work_order(arrange_time,order, cost_time)
    station_id = arrange_time[0]
    started_at = Time.now
    ended_at = started_at + cost_time.minutes
    wo_time = WkOrTime.find_by_station_id_and_current_day station_id, Time.now.strftime("%Y%m%d").to_i if station_id
    if wo_time
      wo_time.update_attributes( :wait_num => wo_time.wait_num.to_i + 1)
    else
      WkOrTime.create(:current_times => ended_at.strftime("%Y%m%d%H%M"), :current_day => Time.now.strftime("%Y%m%d").to_i,
        :station_id => station_id, :worked_num => 1) if station_id and ended_at.present?
    end
    work_order = WorkOrder.create({
        :order_id => order.id,
        :current_day => Time.now.strftime("%Y%m%d"),
        :station_id => station_id || nil,
        :store_id => order.store_id,
        :status => (arrange_time[2] ? WorkOrder::STAT[:SERVICING] : WorkOrder::STAT[:WAIT]),
        :started_at => arrange_time[2] ? started_at : nil,
        :ended_at => arrange_time[2] ? ended_at : nil,
        :cost_time => cost_time
      })

    hash = {}
    hash[:status] = (work_order.status == WorkOrder::STAT[:SERVICING]) ? Order::STATUS[:SERVICING] : Order::STATUS[:NORMAL]
    hash[:station_id] = station_id if station_id  #这个可能暂时没有值，一个完成后要更新
    hash[:started_at] = arrange_time[2] ? started_at : nil
    hash[:ended_at] = arrange_time[2] ? ended_at : nil
    station_staffs = StationStaffRelation.find_all_by_station_id_and_current_day station_id, Time.now.strftime("%Y%m%d").to_i if station_id
    tech_orders = TechOrder.where(:order_id=>order.id)
    if tech_orders.blank?
      if station_staffs
        TechOrder.create(:staff_id=>station_staffs[0].staff_id ,:order_id=>order.id) if station_staffs.size > 0
        TechOrder.create(:staff_id=>station_staffs[1].staff_id,:order_id=>order.id) if station_staffs.size > 1
      else
        TechOrder.create(:order_id=>order.id)
        TechOrder.create(:order_id=>order.id)
      end
    end

    return hash
  end
end

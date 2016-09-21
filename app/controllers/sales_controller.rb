#encoding: utf-8
class SalesController < ApplicationController #活动页
  require 'digest/sha1'
  require 'net/http'
  require "uri"
  require 'openssl'
  require "open-uri"
  require "tempfile"
  #用于处理相应服务号的请求以及

  def index
    customer = Customer.where(:status=>Customer::STATUS[:NOMAL], :openid=>params[:open_id],:store_id=>Constant::STORE_ID).first
    @cpr = CPcardRelation.where(:customer_id=>customer.id,:package_card_id=>Constant::PACKAGE_CARD_ID).first if customer
    @title = "活动"
  end

  #报名参加活动
  def baoming
    open_id = params[:open_id]
    @customer = Customer.where(:status=>Customer::STATUS[:NOMAL], :openid=>params[:open_id],:store_id=>Constant::STORE_ID).first
    if @customer.nil?
      redirect_to "/sales/regist?open_id=#{open_id}"
    else
      @car_num = CustomerNumRelation.find_by_sql(["select cn.num from customer_num_relations cnr inner join
            car_nums cn on cnr.car_num_id=cn.id where cnr.customer_id=?", @customer.id]).first
      render "baoming"
    end
  end

  #注册
  def regist
    @title = "注册"
    @open_id = params[:open_id]
  end

  #创建客户并参加活动
  def create
    phone, num, code = params[:mobilephone], params[:num].strip, params[:valid_code]
    @open_id = params[:open_id]
    @status = 1
    @msg = ""
    begin
      sm_check = SmCheck.where(["mobilephone=? and valid_code=? and status=?", phone, code,SmCheck::STATUS[:UNVALID]]).first
      if sm_check.nil?
        @status = 0
        @msg = "验证码或手机号错误!"
      else
        SmCheck.transaction do
          customer = Customer.joins(:customer_num_relations=>:car_num).where(:"car_nums.num"=>num,:"customers.store_id"=>Constant::STORE_ID).
            where(:status=>Customer::STATUS[:NOMAL]).first
          customer = Customer.create(:mobilephone => phone, :is_vip => 0, :status => 0, :types => 2,
            :store_id => Constant::STORE_ID, :openid =>@open_id)  if customer.nil?
          cn = CarNum.where(:num =>num).first
          cn = CarNum.create(:num => num,:car_model_id=>1) if cn.nil?
          CustomerNumRelation.create(:customer_id => customer.id, :car_num_id => cn.id)
          p_card = PackageCard.find_by_id(Constant::PACKAGE_CARD_ID)
          pcard_prods = PcardProdRelation.where(["package_card_id=?", p_card.id])
          prod_con = []
          content = "您成功了领取了“久久久车管家”的套餐卡#{p_card.name}一张,包含项目"
          pcard_prods.each do |pp|
            prod = Product.find_by_id(pp.product_id)
            prod_con << "#{pp.product_id}-#{prod.name}-#{pp.product_num}"
            content += "#{prod.name}#{pp.product_num}次,请凭手机号和车牌到门店使用。"
          end if pcard_prods.any?
          CPcardRelation.create(:customer_id => customer.id, :package_card_id => p_card.id,
            :ended_at => p_card.ended_at, :status => CPcardRelation::STATUS[:NORMAL],
            :content => prod_con.join(","), :price => p_card.price) if prod_con.any?
          sm_check.update_attributes({:open_id =>@open_id, :status => SmCheck::STATUS[:VALID]})
          @msg = content
          #          access_token = get_token
          #          @res = access_token["access_token"]
          #          content_by_type(open_id, content)
          #          send_action = "/cgi-bin/message/custom/send?access_token=#{get_token["access_token"]}"
          #          response = create_post_http(WEIXIN_API_URL ,send_action, content_by_type(open_id, content))
        end
      end
    rescue
      @status = 0
      @msg = "数据错误!"
    end
  end

  #老用户参加活动
  def update
    @status = 1
    @msg = ""
    valid_code = params[:valid_code]
    begin
      customer = Customer.find_by_id(params[:id].to_i)
      sm_check = SmCheck.where(["mobilephone=? and valid_code=? and status=?", customer.mobilephone, valid_code,SmCheck::STATUS[:UNVALID]]).first
      if sm_check.nil?
        @status = 0
        @msg = "验证码或手机号错误!"
      else
        SmCheck.transaction do
          sm_check.update_attributes({:open_id => customer.openid, :status => SmCheck::STATUS[:VALID]})
          p_card = PackageCard.find_by_id(Constant::PACKAGE_CARD_ID)
          pcard_prods = PcardProdRelation.where(["package_card_id=?", p_card.id])
          prod_con = []
          content = "您成功了领取了“久久久车管家”的套餐卡#{p_card.name}一张,包含项目"
          pcard_prods.each do |pp|
            prod = Product.find_by_id(pp.product_id)
            prod_con << "#{pp.product_id}-#{prod.name}-#{pp.product_num}"
            content += "#{prod.name}#{pp.product_num}次,请凭手机号和车牌到门店使用。"
          end if pcard_prods.any?
          CPcardRelation.create(:customer_id => customer.id, :package_card_id => p_card.id,
            :ended_at => p_card.ended_at, :status => CPcardRelation::STATUS[:NORMAL],
            :content => prod_con.join(","), :price => p_card.price) if prod_con.any?
          @msg = content
        end
      end
    rescue
      @status = 0
      @msg = "验证码或手机号错误!"
    end
  end

  #获取验证码
  def get_valid_code
    status = 0
    begin
      SmCheck.transaction do
        mobile_phone = params[:mobile]
        customer = Customer.where(:status=>Customer::STATUS[:NOMAL], :mobilephone=>mobile_phone,:store_id=>Constant::STORE_ID).first
        cpr = CPcardRelation.where(:customer_id=>customer.id,:package_card_id=>Constant::PACKAGE_CARD_ID).first if customer
        if cpr.nil?
          SmCheck.where(["mobilephone=? and status=?", mobile_phone, SmCheck::STATUS[:UNVALID]]).delete_all
          code = SmCheck.make_code(4)
          SmCheck.create(:store_id => Constant::STORE_ID, :sale_id => Constant::SALE_ID, :mobilephone => mobile_phone,
            :valid_code => code, :status => SmCheck::STATUS[:UNVALID])
          send_url = "http://nf-lantan.icar99.com"
          message_route = "/messages/wechat_msg?store_id=#{Constant::STORE_ID}&code=#{code}&phone=#{mobile_phone}"
          create_get_http(send_url, message_route)
          status =1
        end
      end
    rescue
    end
    render :json => {:status => status}
  end

  def show
    @sale = Sale.find params[:id]
  end


  #用于处理相应服务号的请求以及
  def accept_token
    signature, timestamp, nonce, echostr= params[:signature], params[:timestamp], params[:nonce], params[:echostr]
    store = Store.find params[:id]
    tmp_encrypted_str = get_signature(timestamp, nonce)
    if request.request_method == "POST" && tmp_encrypted_str == signature
      open_id = params[:xml][:FromUserName]
      if params[:xml][:MsgType] == "event"
        if params[:xml][:Event] == "subscribe"   #用户关注事件
          create_menu(get_token(store),open_id,params[:id])
        elsif params[:xml][:Event] == "CLICK"
          message = "开发中，敬请期待！"
        end
        sale = Sale.on_weixin(store.id).valid.first
        if sale.nil?
          message = "欢迎关注“#{store.name}”！请关注最新活动"
        else
          message = "欢迎关注“#{store.name}”！请关注最新活动&lt;a href='#{SERVER_PATH}/sales/#{sale.id}'&gt; #{sale.name},&lt;/a&gt;,详情猛戳查看"
        end
        render :xml => teplate_xml(message)
      elsif params[:xml][:MsgType] == "text"   #用户发送文字消息
        content = params[:xml][:Content]
        sale = Sale.on_weixin(store.id).valid.first
        if sale.nil?
          message = "欢迎关注“#{store.name}”！请关注最新活动"
        else
          message = "欢迎关注“#{store.name}”！请关注最新活动&lt;a href='#{SERVER_PATH}/sales/#{sale.id}'&gt; #{sale.name},&lt;/a&gt;,详情猛戳查看"
        end
        render :xml => teplate_xml(message)
      elsif params[:xml][:MsgType] == "text"   #用户发送文字消息
      else
        render :text => "ok"
      end
    elsif request.request_method == "GET" && tmp_encrypted_str == signature  #配置服务器token时是get请求
      render :text => tmp_encrypted_str == signature ? echostr :  false
    end
  end
  
end

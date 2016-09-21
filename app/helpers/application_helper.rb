#encoding: utf-8
module ApplicationHelper
  require 'net/http'
  require "uri"
  require 'openssl'
  include Constant

  # 中英文混合字符串截取
  def truncate_u(text, length = 30, truncate_string = "......")
    l=0
    char_array=text.unpack("U*")
    char_array.each_with_index do |c,i|
      l = l+ (c<127 ? 0.5 : 1)
      if l>=length
        return char_array[0..i].pack("U*")+(i<char_array.length-1 ? truncate_string : "")
      end
    end
    return text
  end

  def binded?
    redirect_to "/stores/#{params[:store_id]}/bind_user?openid=#{params[:openid]}" if params[:openid].nil? || Customer.where(:openid => params[:openid],:store_id => params[:store_id]).first.nil?
  end

  def mkdir_txt(dir_name,file_name)
    total_dir = ["",dir_name,Time.now.strftime("%Y-%m-%d"),""]
    total_dir.each_with_index do |dir,index|
      Dir.mkdir "#{Rails.root}"+total_dir[0..index].join("/")  unless File.directory? "#{Rails.root}"+total_dir[0..index].join("/")
    end
    "#{Rails.root}"+total_dir.join("/")+file_name+".txt"
  end

  def record_request(types,content)
    file_path = mkdir_txt("requests","request_url")
    file = File.open(file_path,"a+")
    file.write("\r\n#{types}----#{content}\r\n".force_encoding("UTF-8"))
    file.close
  end

  #文本回复模板
  def teplate_xml(message)
    template_xml =
      <<Text
          <xml>
            <ToUserName><![CDATA[#{params[:xml][:FromUserName]}]]></ToUserName>
            <FromUserName><![CDATA[#{params[:xml][:ToUserName]}]]></FromUserName>
            <CreateTime>#{Time.now.to_i}</CreateTime>
            <MsgType><![CDATA[text]]></MsgType>
            <Content>#{message}</Content>
            <FuncFlag>0</FuncFlag>
          </xml>
Text
    template_xml
  end

  def get_token(store)
    token_action = ACCESS_TOKEN_ACTION % [store.app_id, store.app_secret]
    create_get_http(WEIXIN_API_URL ,token_action)
  end

  #验证请求是否从微信发出
  def get_signature(timestamp, nonce)
    Digest::SHA1.hexdigest([TOKEN, timestamp, nonce].compact.sort!.join)
  end

  #发get请求获得access_token
  def create_get_http(url ,route)
    http = set_http(url)
    request= Net::HTTP::Get.new(route)
    back_res = http.request(request)
    record_request(0,url+route)
    return JSON back_res.body
  end

  #发post请求创建自定义菜单
  def create_post_http(url,route_action,menu_bar)
    http = set_http(url)
    request = Net::HTTP::Post.new(route_action)
    request.set_body_internal(menu_bar)
    response = JSON http.request(request).body
    record_request(1,response)
    return response
  end

  #设置http基本参数
  def set_http(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.port==443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    http
  end


  #公众号发消息给用户的模板
  def content_by_type(open_id, content)
    content_hash = {
      :touser =>"#{open_id}",
      :msgtype => "text",
      :text =>{:content => content}
    }
    content_hash.to_json.gsub!(/\\u([0-9a-z]{4})/) {|s| [$1.to_i(16)].pack("U")}
  end


  def unauth_send(content,wx_token) #订阅号或者未认证的服务号  发送信息hack
    http = set_http(WEIXIN_URL)
    post_data = 't=ajax-response&type=1&content=%s&error=false&imgcode=&token=%s&ajax=1&tofakeid=' % [content, wx_token]   # fakeid = ?
    post_data = (post_data + to_faker_id).encode('utf-8')
    header = {"Cookie" => wx_cookie,
      "referer" => 'https://mp.weixin.qq.com/cgi-bin/singlemsgpage?&token=%s&fromfakeid=%s'+
        '&msgid=&source=&count=20&t=wxm-singlechat&lang=zh_CN' % [wx_token, gzh_client.faker_id]
    }  # 添加 HTTP header 里的 referer 欺骗腾讯服务器。如果没有此 HTTP header，将得到登录超时的错误。
    msg = ""
    http.request_post(WEIXIN_SEND_MESSAGE_ACTION, post_data, header) {|response|
      res =  JSON response.body
      if res["base_resp"]["ret"] == 0
        msg = "success"
      elsif res["base_resp"]["ret"].blank?  #数据库的token超时，重新登录
        login_info = login_to_weixin(company)
        if login_info.present?
          wx_token, wx_cookie = login_info
          send_message_request(company, content, gzh_client, to_faker_id, wx_token, wx_cookie)
        end
      else
        msg = ""
      end
    }
    msg
  end


  #获取自身faker_id
  def get_self_fakeid(wx_cookie, token)
    http = set_http(WEIXIN_URL)
    user_fakeid = nil
    setting_action = WEIXIN_USER_SETTING_ACTION % token
    http.request_get(setting_action,{"Cookie" => wx_cookie} ) {|response|
      fakeid_arr = response.body.scan(/fakeid=(\w+)/)
      user_fakeid = fakeid_arr.flatten[0]
    }
    user_fakeid
  end

  #创建自定义菜单
  def create_menu(access_token,openid,store_id)
    if access_token && access_token["access_token"]
      c_menu_action = CREATE_MENU_ACTION % access_token["access_token"]
      create_post_http(WEIXIN_API_URL ,c_menu_action ,menu_str(openid,store_id))
    end
  end

  def menu_str(openid,store_id)
    menu = {
      "button"=>[
        {
          "name"=>"门店查询",
          "type"=>"view",
          "url"=>"http://sale.icar99.com/stores/#{store_id}?openid=#{openid}"
        },
        {
          "name"=>'活动',
          "type"=>'click',
          'key'=>"101"
        },
        {
          "name"=>"会员服务",
          "type"=>"click",
          "key"=>"201"
        }
      ]
    }
    "#{menu}".gsub("=>",":")
  end

  def is_array?(arr)
    return arr.class == Array
  end
end


#获取自身faker_id
def get_self_fakeid(wx_cookie, token)
  http = set_http(WEIXIN_API_URL)
  user_fakeid = nil
  setting_action = WEIXIN_USER_SETTING_ACTION % token
  http.request_get(setting_action,{"Cookie" => wx_cookie} ) {|response|
    fakeid_arr = response.body.scan(/fakeid=(\w+)/)
    user_fakeid = fakeid_arr.flatten[0]
  }
  user_fakeid
end


#登录微信
def login_to_weixin(company)
  data_param = "username=#{USERNAME}&pwd=#{PWD}&imgcode=''&f=json"
  http = set_http(WEIXIN_API_URL)

  wx_cookie, slave_user, slave_sid, token = "", nil, nil, nil
  http.request_post(WEIXIN_LOGIN_ACTION, data_param, {"x-requested-with" => "XMLHttpRequest",
      "referer" => "https://mp.weixin.qq.com/cgi-bin/loginpage?t=wxm2-login&lang=zh_CN"}) {|response|
    res_data = JSON response.body   #   {"Ret"=>302, "ErrMsg"=>"/cgi-bin/home?t=home/index&lang=zh_CN&token=155671926", "ShowVerifyCode"=>0,"ErrCode"=>0, "WtloginErrCode"=>0}
    if res_data["ErrCode"] == 0
      wx_cookie_str = response['set-cookie']  #获取cookie的值
      #"slave_user=gh_91dc23d9899e; Path=/; Secure; HttpOnly, slave_sid=NjJyWU9CMllLYWNRS0w4Tk05YXk3NlRjR09MZVQzOUFNSGRVR3lEcG1Pc1lYS1BPMEZ5dVduNGdCQnRVYnZHRnpOdlF3UmllRVVRak50ZlZmTWs3TkZ1YmhLQWxJWWR3RXRWMXhxSzRPdkZFSjFLRUNiblFrcHB6c1ZkdHVNWE0=; Path=/; Secure; HttpOnly"
      slave_user = wx_cookie_str.scan(/slave_user=(\w+);/).flatten[0]  #当前登录用户
      slave_sid = wx_cookie_str.scan(/slave_sid=(\w+=)/).flatten[0] #当前登录用户id

      wx_cookie = "slave_user=#{slave_user}; slave_sid=#{slave_sid};"
      msg =res_data["ErrMsg"]
      token = msg.scan(/token=(\d+)/).flatten[0] #登录后的token

      gzh_client = Client.find_by_company_id_and_types(company.id, Client::TYPES[:ADMIN]) #公众号client
      gzh_client.update_attributes(:wx_login_token => token, :wx_cookie => wx_cookie) #更新公众号faker_id
    else
      message = "login error"
      return false
    end
  }

  if slave_user && slave_sid && token
    return [token, wx_cookie]
  else
    return false
  end



end




#encoding: utf-8
module Constant
  STORE_ID = 100013
  CAR_MODEL_ID = 3
  SALE_ID = 99
  PACKAGE_CARD_ID = 3
  MESSAGE_URL = "http://mt.yeion.com"
  USERNAME = "XCRJ"
  PASSWORD = "123456"
  SALE_PICSIZE =[300,230,663,50]
  P_PICSIZE = [50,154,246,300,356,800]
  #数据服务器
  SERVER_PATH = "http://localhost:3001"
  #  SERVER_PATH = "http://sale.icar99.com"
  WEIXIN_API_URL = "https://api.weixin.qq.com"  #微信api地址
  ACCESS_TOKEN_ACTION = "/cgi-bin/token?grant_type=client_credential&appid=%s&secret=%s" #微信获取access_token action
  WEIXIN_USER_SETTING_ACTION = '/cgi-bin/settingpage?t=setting/index&action=index&token=%s&lang=zh_CN' #公众号设置页面action，获取自身faker_id
  #  久久久
  #  APPID = "wx1e0ba158173f87e8"
  #  APPSERECT = "3317a031c43a2578be22cc3818a6d31e"
  #澜泰
  APPID = "wx22309dc592265794"
  APPSERECT = "6fab53d3dcb7d596b47fcfe4d6f226ee"

  MICRO_STORE = [150,230]

  #  账号和密码
  WX_USERNAME = "1635420259@qq.com"
  WX_PWD = "lantaikeji668"

  TOKEN = "lantan1980876543219087654"
  CREATE_MENU_ACTION = "/cgi-bin/menu/create?access_token=%s" #创建自定义菜单action

  #订阅号 hack action
  WEIXIN_URL = 'https://mp.weixin.qq.com' #微信公众号url


end
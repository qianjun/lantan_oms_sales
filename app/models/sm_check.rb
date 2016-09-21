#encoding: utf-8
class SmCheck < ActiveRecord::Base
  STATUS = {:UNVALID => 0, :VALID => 1}
  S_STATUS = {0 => "无效", 1 => "有效"}

  #生成验证码
  def self.make_code(len=12)
    chars = (1..9).to_a
    code=(1..len).inject(Array.new) {|codes| codes << chars[rand(chars.length)]}.join("")
    has_exist = SmCheck.where(["valid_code=?", code])
    if has_exist.any?
      make_code
    else
      return code
    end
  end

end
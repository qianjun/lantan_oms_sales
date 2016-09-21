#encoding: utf-8
class Department < ActiveRecord::Base
  TYPES = {:POSITION => 0, :DEPARTMENT => 1} #0职务 1部门
  STATUS = {:NORMAL => 0, :DELETED => 1} #0正常 1删除
end

# encoding: utf-8
require 'error_enum'
class CarnivalLog

  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool
  include ViewHelper
  # log type，2表示获得第一关话费，3表示抽得第二关话费，4表示获取第三关话费，5表示抽到第三关大奖，6表示分享成功获得抽奖机会，7表示分享抽到大奖
  STAGE_1 = 2
  STAGE_2 = 3
  STAGE_3 = 4
  STAGE_3_LOTTERY = 5
  SHARE = 6
  SHARE_LOTTERY = 7

  field :type, :type => Integer
  field :prize_name, :type => String

  belongs_to :carnival_user

  def self.recent_logs
    self.all.desc(:created_at).limit(10)
  end
end
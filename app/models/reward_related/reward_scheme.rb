# encoding: utf-8
require 'error_enum'
class RewardScheme
  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool
    
  MOBILE = 1
  ALIPAY = 2
  POINT = 4
  LOTTERY = 8
  JIFENBAO = 16
  HONGBAO  = 32
  
  CASH_REWARD = "1,2,16,32"
  FREE = "0"

  field :name, type: String, default: ""
  field :rewards, type: Array, default: []
  field :need_review, type: Boolean, default: false
  field :default, type: Boolean, default: false

  belongs_to :survey
  has_many :answers
  has_many :agent_tasks

  scope :not_default, where(default: false)

  index({ default: 1 }, { background: true } )


  def self.create_reward_scheme(survey, reward_scheme)
    retval = verify_reward_scheme_type(reward_scheme)
    return retval if !(retval.to_s == "true")
    new_reward_scheme = RewardScheme.create(reward_scheme)
    survey.reward_schemes << new_reward_scheme
    return new_reward_scheme
  end

  def self.verify_reward_scheme_type(reward_scheme)
    retval = true
    reward_scheme["rewards"].each do |reward|
      reward["type"] = ([1, 2, 4, 8, 16].include?(reward["type"].to_i) ? reward["type"] : 4)   ##Verify type
    end
    reward_scheme["need_review"] = false if !(reward_scheme["need_review"].to_s == "true")
    return retval
  end

  def self.first_reward_by_survey(id)
    reward = self.find_by_id(id)
    info = reward.rewards[0] if reward.present?
    if info.present? && info['type'].to_i == RewardScheme::LOTTERY
      info['prize_arr'] = []
      ids = info['prizes'].map{|priz| priz['id']}
      prizes = Prize.where(:_id.in => ids)
      prize_info = {}
      prizes = prizes.each do |prize|
        prize_info['prize_id']  = prize.id
        prize_info['title'] = prize.title
        prize_info['price'] = prize.price
        prize_info['description'] = prize.description
        prize_info['prize_src'] = prize.photo.present? ? prize.photo.picture_url : Prize::DEFAULT_IMG 
        info['prize_arr'] << prize_info
        prize_info = {}  
      end       
    end
    return info
  end

  def new_answer(answer)
    answer.rewards = self.rewards
    answer.rewards[0]["checked"] = true if self.rewards.length == 1
    answer.need_review = self.need_review
    self.answers << answer
    answer.save
  end


  def wechart_reward_amount
    hash = self.rewards.select{|hash| hash['type'] == 32}
    if hash.length > 0
      return hash.first['amount']
    else
      return nil
    end
  end
  


end

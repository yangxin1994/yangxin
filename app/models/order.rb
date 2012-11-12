class Order
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ValidationsExt
  extend Mongoid::FindHelper
  # can be 0 (Cash), 1 (Entity), 2 (Virtual), 3 (Lottery)
  field :type, :type => Integer
  # can be 0 (NeedVerify), 1 (Verified), -1 (VerifyFailed), 2 (Delivering), 3 (Delivered), -3 (DeliverFailed)
  field :status, :type => Integer, :default => 0
  field :status_desc, :type => String
  field :is_deleted, :type => Boolean, :default => false 

  field :is_update_user, :type => Boolean, :default => false
  field :full_name, :type => String
  field :identity_card, :type => String
  field :bank, :type => String
  field :bankcard_number, :type => String
  field :alipay_account, :type => String
  field :phone, :type => String
  field :address, :type => String
  field :postcode, :type => String
  field :email, :type => String

  # embeds_one :cash_receive_info, :class_name => "CashReceiveInfo"
  # embeds_one :entity_receive_info, :class_name => "EntityReceiveInfo"
  # embeds_one :virtual_receive_info, :class_name => "VirtualReceiveInfo"
  # embeds_one :lottery_receive_info, :class_name => "LotteryReceiveInfo"

  has_one :reward_log, :class_name => "RewardLog"

  belongs_to :gift, :class_name => "BasicGift"
  belongs_to :user, :class_name => "User", :inverse_of => :orders
  belongs_to :operator, :class_name => "User", :inverse_of => :operate_orders
  
  validates :type, :presence_ext => true,
                   :inclusion => { :in => 0..3 },
                   :numericality => true
  validates :status, :presence_ext => true,
                     :inclusion => { :in => -3..3 },
                     :numericality => true

  scope :for_cash, where( :type => 0)
  scope :for_entity, where( :type => 1)
  scope :for_virtual, where( :type => 2)
  scope :for_lottery, where( :type => 3)

  scope :need_verify, where( :status => 0)
  scope :verified, where( :status => 1)
  scope :verify_failed, where( :status => -1)
  scope :delivering, where( :status => 2)
  scope :delivered, where( :status => 3)
  scope :deliver_failed, where( :status => -3)

  # TO DO validation verify
  # We must follow the Law of Demeter(summed up as "use only one dot"), and here is the code: 
  delegate :name, :to => :gift, :prefix => true
  #delegate :cash_order, :realgoods_order, :to => "self.need_verify", :prefix => true
  #after_create :decrease_point, :decrease_gift

  # TO DO I18n
  after_create :decrease_gift, :update_user_info

  private
  
  def decrease_gift
    return false if self.gift.blank? || self.user.blank?
    if self.gift.type == 3
      self.gift.lottery.give_lottery_code_to(self.user) 
    end
    self.create_reward_log(:order => self,
                           :type => 1,
                           :user => self.user,
                           :point => -self.gift.point,
                           :cause => 4)
    self.gift.inc(:surplus, -1) 
    self.save
  end

  def update_user_info
    return false if self.user.blank?
    return true unless self.is_update_user
    case self.type
    when 0
      self.user.update_attributes({
        :full_name => self.full_name,
        :identity_card => self.identity_card,
        :bank => self.bank,
        :bankcard_number => self.bankcard_number,
        :alipay_account => self.alipay_account,
        :phone => self.phone},
        :without_protection => true)
    when 1
      self.user.update_attributes({
        :full_name => self.full_name,
        :address => self.address,
        :postcode => self.postcode,
        :phone => self.phone},
        :without_protection => true)
    when 2
      self.user.update_attributes({
        :full_name => self.full_name,
        :phone => self.phone},
        :without_protection => true)
    when 3
    end
    #self.user.update_attributes(self.attributes, :without_protection => true)
  end

end

class CashReceiveInfo
  include Mongoid::Document
  field :need_update, :type => Boolean
  field :full_name, :type => String
  field :identity_card, :type => String
  field :bank, :type => String
  field :bankcard_number, :type => String
  field :alipay_account, :type => String
  field :phone, :type => String
  embedded_in :order
  after_create :update_user_info
  def update_user_info
    return true unless self.need_update
    p self.attributes
    #self.user.update_attributes(self.attributes, :without_protection => true)
  end

end

class EntityReceiveInfo
  include Mongoid::Document
  field :phone, :type => String
  field :full_name, :type => String
  field :address, :type => String
  field :postcode, :type => String
  embedded_in :order
end

class VirtualReceiveInfo
  include Mongoid::Document
  field :full_name, :type => String
  field :phone, :type => String
  embedded_in :order
end

class LotteryReceiveInfo
  include Mongoid::Document
  field :email, :type => String
  embedded_in :order
end


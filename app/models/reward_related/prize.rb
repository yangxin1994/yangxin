class Prize < BasicGift
  #field :budget, :type => Integer
  field :weight, :type => Integer, :default => 10

  field :is_in_ctrl, :type => Boolean, :default => false
  field :ctrl_surplus, :type => Integer, :default => 0
  field :ctrl_quantity, :type => Integer, :default => 0
  field :ctrl_time, :type => Integer, :default => 0
  field :ctrl_start_time, :type => Time, :default => Time.now
  field :ctrl_history, :type => Array, :default => []

  scope :can_be_draw, where('$and' => [:is_in_ctrl => true, :ctrl_surplus.gt => 0, :status.gt => -1]).where(:is_deleted => false )
  scope :can_be_autodraw, where(:status.gt => -1).where(:is_deleted => false )
  scope :for_lottery, where(:lottery_id => nil).where(:is_deleted => false )
  scope :all_d, where(:is_deleted => false )
  attr_accessible :name, :type, :surplus, :description, :photo, :is_deleted

  has_one :order, :inverse_of => 'gift'
  belongs_to :lottery, :inverse_of => 'prizes'
  has_many :lottery_codes
  has_one :photo, :class_name => "Material", :inverse_of => 'prize'

  index({ is_deleted: 1, status: 1, is_in_ctrl: 1, ctrl_surplus: 1 }, { background: true } )
  index({ is_deleted: 1, lottery_id: 1 }, { background: true } )

  before_save :update_ctrl_time

  before_create :add_ctrl_history

  def present_quillme
    present_attrs :name, :type, :description, :surplus, :_id
    present_add photo_src: self.photo.picture_url
  end

  def present_admin
    present_attrs :name, :type, :description, :surplus, :_id, :ctrl_surplus,
                  :ctrl_quantity, :ctrl_time, :ctrl_start_time, :ctrl_history
    present_add photo_src: self.photo.picture_url
  end

  def validates_ctrl

  end

  def add_ctrl_history
    h = {
      :name => self.name,
      :ctrl_quantity => self.ctrl_quantity,
      :ctrl_time => self.ctrl_time,
      :ctrl_start_time => self.ctrl_start_time,
      :ctrl_surplus => self.ctrl_surplus,
      :weight => self.weight
    }
    self.ctrl_history << h
  end

  def add_ctrl_rule(ctrl_surplus, ctrl_time, weight)
    unless ctrl_surplus.blank? || ctrl_time.blank? || weight.blank?
      return false if ctrl_surplus.to_i > self.surplus
      return false if ctrl_time.to_i <= 0 || weight.to_i <= 0
      self.is_in_ctrl = true
      self.ctrl_surplus = ctrl_surplus.to_i
      self.ctrl_quantity = ctrl_surplus.to_i
      self.ctrl_start_time = Time.now
      self.ctrl_time = ctrl_time.to_i
      self.weight = weight.to_i
      add_ctrl_history
      self.save
    else
      return false
    end
  end

  def update_ctrl_surplus
    self.ctrl_surplus -= 1
    if self.ctrl_surplus <= 0
      self.is_in_ctrl = false
    end
    self.ctrl_history.last["ctrl_surplus"] = self.ctrl_surplus
    self.save
  end

  def update_ctrl_time
    return true if self.is_in_ctrl == false
    if (self.ctrl_start_time + self.ctrl_time.days) <= Time.now
      self.is_in_ctrl = false
      add_ctrl_history
    end
  end

  def active_ctrl_history
    self.ctrl_history.last ? [self.ctrl_history.last] : []
  end

end
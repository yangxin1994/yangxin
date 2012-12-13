class Prize < BasicGift
  
  #field :budget, :type => Integer
  field :weight, :type => Integer, :default => 10

  field :is_in_ctrl, :type => Boolean, :default => false
  field :ctrl_surplus, :type => Integer
  field :ctrl_quantity, :type => Integer
  field :ctrl_time, :type => Integer
  field :ctrl_start_time, :type => Time
  field :ctrl_history, :type => Array, :default => []
  scope :can_be_draw, where('$and' => [:is_in_ctrl => true, :ctrl_surplus.gt => 0, :status.gt => -1])
  scope :for_lottery, where(:lottery_id => nil)
  
  has_one :order
  belongs_to :lottery
  has_many :lottery_codes
  has_one :photo, :class_name => "Material", :inverse_of => 'prize'

  before_save :update_ctrl_time 
  
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
    self.is_in_ctrl = true
    self.ctrl_surplus = ctrl_surplus
    self.ctrl_quantity = ctrl_surplus
    self.ctrl_start_time = Time.now
    self.ctrl_time = ctrl_time
    self.weight = weight
    add_ctrl_history
    self.save
  end

  def update_ctrl_surplus
    self.ctrl_surplus -= 1
    if self.ctrl_surplus <= 0
      self.is_in_ctrl = false
    end
    self.save
  end

  def update_ctrl_time
    return true if self.is_in_ctrl == false 
    if (self.ctrl_start_time + self.ctrl_time.days) <= Time.now
      self.is_in_ctrl = false 
      add_ctrl_history
    end
  end

end
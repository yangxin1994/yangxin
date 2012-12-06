class Prize < BasicGift
  
  #field :budget, :type => Integer
  field :weight, :type => Integer, :default => 10
  field :ctrl_type, :type => Integer, :default => -1
  field :ctrl_surplus, :type => Integer
  field :ctrl_quantity, :type => Integer
  field :ctrl_loop, :type => Integer, :default => 0
  field :ctrl_custom, :type => Integer
  field :ctrl_start_time, :type => Time

  scope :can_be_draw, where('$and' => 
    [{'$or' =>
      [{:ctrl_type => -1},:ctrl_surplus.gt => 0]},
    {:status => 1}
  ])
  scope :for_lottery, where(:lottery_id => nil)
  


  has_one :order
  belongs_to :lottery
  has_many :lottery_codes
  has_one :photo, :class_name => "Material", :inverse_of => 'prize'

  before_save :update_ctrl_time

  def validates_ctrl
    
  end

  def current_loop_time
    self.ctrl_start_time = Time.now if self.ctrl_start_time.nil?
    case self.ctrl_type
    when -1
      return true
    when 0
      self.ctrl_custom = 1 if self.ctrl_custom.nil?
      return self.ctrl_start_time + (self.ctrl_loop * self.ctrl_custom).days
    when 1
      return self.ctrl_start_time + self.ctrl_loop.days
    when 2
      return self.ctrl_start_time + (self.ctrl_loop * 7).days
    when 3
      return self.ctrl_start_time + (self.ctrl_loop * 30).days
    end
  end

  def update_ctrl_time
    if self.ctrl_type != -1 && Time.now >= current_loop_time
      self.ctrl_loop += 1
      self.ctrl_start_time = Time.now if self.ctrl_start_time.nil?
      self.ctrl_surplus = self.ctrl_quantity
    end
    return true
  end

  def update_ctrl_surplus
    if self.ctrl_type == -1
      true
    else
      self.ctrl_surplus -= 1
      self.save
    end
  end

end
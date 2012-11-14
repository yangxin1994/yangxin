class Prize < BasicGift
	
	#field :budget, :type => Integer
  field :weighting, :type => Integer, :default => 10
  field :status, :type => Integer, :default => 1
  # can be -1 (has no), 0 (expired), 1 (can be rewarded)
  scope :can_be_draw, where(:status => 0)
  scope :for_lottery, where(:lottery_id => nil)
  
	has_one :order
	belongs_to :lottery
	belongs_to :lottery_code
  has_one :photo, :class_name => "Material", :inverse_of => 'prize'

	#before_save :make_status

  def make_status
    status = -1 if (self.surplus <= 0)
  end

	#validates_presence_of :type
	#validates :budget, :spend => { :size => :big }

end
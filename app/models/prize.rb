class Prize < BasicGift
	
	#field :budget, :type => Integer
  field :weight, :type => Integer, :default => 10

  scope :can_be_draw, where(:status => 1)
  scope :for_lottery, where(:lottery_id => nil)
  scope :wined, where(:status => 2)
  
	has_one :order
	belongs_to :lottery
	has_many :lottery_codes
  has_one :photo, :class_name => "Material", :inverse_of => 'prize'

	#validates_presence_of :type
	#validates :budget, :spend => { :size => :big }

end
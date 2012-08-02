class Award < BasicPresent
	include Mongoid::Validator
	field :budget, :type => Integer
  field :weighting, :type => Integer, :default => 0
  field :surplus, :type => Integer
  field :quantity, :type => Integer
  field :status, :type => Integer, :default => 1

  scope :can_be_draw, where(:status => 0)

	has_one :order
	has_one :lottery
	
	after_save :make_status

  def make_status
    return unless self.start_time && self.end_time
    status = 0
    status += 1 if Time.now >= end_time
    status += 2 if surplus <= 0
#   status = 4 if Time.now <= start_time
    self.update_attribute(:status, status) if status != self.status
  end

	#validates_presence_of :type
	validates :budget, :spend => { :size => :big }

end
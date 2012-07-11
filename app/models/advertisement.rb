class Advertisement
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :title, :type => String
  field :linked, :type => String
  field :location, :type => String
  field :activate, :type => Boolean, :default => false
  
  belongs_to :user
  
  attr_accessible :title, :linked, :location, :activate
  
  #--
  # scope is same with class methods
  #++
  scope :unactivate, where(activate: false)
  scope :activated, where(activate: true)
  
  #--
  # instance methods
  #++
  
  #*description*: alias of activate attr, more friendly.
  #*params*:
  #
  #*retval*
  # true or false
  def is_activate?
  	return self.activate 
  end
  
  #*description*: update activate attribute value.
  #*params*:
  #
  #*retval*
  # true or false
  def update_activate(bool)
  	self.activate = bool
  	return self.save
  end
  
  #*description*: rewrite save method for mongoid, add user parameter
  #*params*:
  #
  #*retval*
  # true or false
  def save(user=nil)
  	self.user = user if user && user.instance_of?(User)
  	super()
  end
  
  #*description*: rewrite update_answers method for mongoid, add user parameter
  #*params*:
  #
  #*retval*
  # true or false
  def update_attributes(params, user=nil)
  	self.user = user if user && user.instance_of?(User)
  	super(params)
  end
  
  #--
  # class methods
  #++
  
end

class String
  
  # parse string to boolean.
  # return true if string is 'true', or else false
  def to_b
    return (self =~ (/(true|t|yes|y|1)$/i)) ? true : false
    # return true if self == true || self =~ (/(true|t|yes|y|1)$/i)
    # return false if self == false || self.blank? || self =~ (/(false|f|no|n|0)$/i)
    # raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
  
end
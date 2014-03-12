class String
  
  # parse string to boolean.
  # return true if string is 'true', or else false
  def to_b
    return (self =~ (/(true|t|yes|y|1)$/i)) ? true : false
    # return true if self == true || self =~ (/(true|t|yes|y|1)$/i)
    # return false if self == false || self.blank? || self =~ (/(false|f|no|n|0)$/i)
    # raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end

  def remove_style
    return self.gsub(/<r>(.*?)<\/r>/, '\1')
      .gsub(/<u>(.*?)<\/u>/, '\1')
      .gsub(/<big>(.*?)<\/big>/, '\1')
      .gsub(/<b>(.*?)<\/b>/, '\1')
      .gsub(/<bigger>(.*?)<\/bigger>/, '\1')
      .gsub(/<biggest>(.*?)<\/biggest>/, '\1')
      .gsub(/<link>([^\s]*?)<\/link>/, '\1')
      .gsub(/<link>([^\s]*?)\s(.*?)<\/link>/, '\2');
  end
end

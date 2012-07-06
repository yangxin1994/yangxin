class Faq
  include Mongoid::Document
  include Mongoid::Timestamps

  field :faq_type, :type => String
  field :question, :type => String
  field :answer, :type => String

  #--
  # instance methods 
  #++

	#*description*: update one Faq instance by user.    
  # it will verify the user role whether is admin
  #
 	#*params*:
 	#* user instance
  #* hash for update attrs 
 	#
 	#*retval*:
  #true or false
  def instance_update_by_user(user, hash)
    return false if !user.is_admin
    hash.select!{|key, vaule| %{faq_type question answer}.split.include?(key.to_s)}
    return Faq.where(_id: self.id).update(hash)
  end 

  #*description*: destroy faq instance
  #
  #*params*:
  #* user: verify the user is admin, or not.
  #
  #*retval*:
  # true or false
  def instance_destroy_by_user(user)
    return false if !user.is_admin
    return Faq.where(_id: self.id).delete
  end 

  #--
  # class methods
  #++
  class << self
           
	  #*description*: create Faq by user. 
    # it will verify the user role whether is admin
	  #
  	#*params*:
  	#* user instance
  	#
  	#*retval*:
   	#* true or false
    def create_by_user(user, faq_type, question, answer)
      return false if !user.is_admin
      return Faq.new(faq_type: faq_type, question: question, answer: answer).save
    end 

	  #*description*: update one Faq instance by user.    
    # it will verify the user role whether is admin
    #
 	  #*params*:
 	  #* user instance
    #* hash for update attrs 
 	  #
 	  #*retval*:
    #true or false
    def update_by_user(faq_id, user, hash)
      faq = Faq.find(faq_id)
      return faq.instance_update_by_user(user,hash)
    end 

    #*description*: destroy faq instance
    #
    #*params*:
    #* user: verify the user is admin, or not.
    #
    #*retval*:
    # true or false
    def destroy_by_user(faq_id, user)
      faq = Faq.find(faq_id)
      return faq.instance_destroy_by_user(user)
    end 

	  #*description*: list all faq  
  	#
  	#*retval*:
    #faq array
    def list_all
      return Faq.all.desc(:updated_at)
    end
    
    #*description*: list faqs with one condition
  	#
  	#*retval*:
    #faq array
    def condition(key, value)
      return nil if %{type question answer}.split.delete(key.to_s).nil?
    	return Faq.where(faq_type: value).desc(:updated_at) if key.to_s == "type"
      return Faq.where(question: /.*#{value}.*/).desc(:updated_at) if key.to_s == "question"
      return Faq.where(answer: /.*#{value}.*/).desc(:updated_at) if key.to_s == "answer"
    end
  end
end

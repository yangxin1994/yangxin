# coding: utf-8

class Feedback
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :feedback_type, :type => String
  field :title, :type => String
  field :content, :type => String
  field :is_answer, :type => Boolean, :default => false
  
  attr_accessible :feedback_type, :title, :content
  
  belongs_to :question_user, class_name: "User", inverse_of: :question_feedback
  belongs_to :answer_user, class_name: "User", inverse_of: :answer_feedback
  
  scope :answered, where(is_answer: true).desc(:udpated_at)
  scope :unanswer, where(is_answer: false).desc(:updated_at)
  
  #--
  # instance methods
  #++
  
  def is_answer?
  	self.is_answer
  end
  
  #--
  # class methods
  #++
  
  class << self
  	
  	#*description*: create feedback
    #
    #*params*:
    #* feedback_type: type for feedback
    #* title: feedback 's title
    #* content: feedback 's content
    #* question_user:  feedback user
    #
    #*retval*:
    #* false or true
  	def create(feedback_type, title, content, question_user=nil)
  		
  		return false if question_user && !question_user.instance_of?(User)
  		
  		feedback = Feedback.new(feedback_type: feedback_type, 
  					title: title, content: content)
			feedback.question_user = question_user if question_user
			
			return feedback.save 
  	end
  	
  	#*description*: update feedback
    #
    #*params*:
    #* feedback_id
    #* hash: hash of feedback attrs
    #* question_user:  feedback user
    #
    #*retval*:
    #* false or true
  	def update(feedback_id, hash, question_user=nil)
  		
  		return false if question_user && !question_user.instance_of?(User)
  		
  		#find feedback
  		feedback = Feedback.find(feedback_id)
      return false if feedback.nil?
      
      #if feedback has question_user,
      #verify question_user with db feedback question_user 
      if feedback.question_user then
      	return false if question_user.nil?
      	return false if question_user.id.to_s != feedback.question_user.id.to_s
      end

      hash.select!{|k,v| %{feedback_type title content is_answer}.split.include?(k.to_s)}
      feedback.update_attributes(hash)
      return feedback.save 
  	end
  	
  	#*description*: destroy feedback
    #
    #*params*:
    #* feedback_id: 
    #* question_user:  feedback user
    #
    #*retval*:
    #* false or true
  	def destroy(feedback_id, question_user=nil)
  		
  		return false if question_user && !question_user.instance_of?(User)
  		
  		#find feedback
  		feedback = Feedback.find(feedback_id)
      return false if feedback.nil?
      
      #if feedback has question_user,
      #verify question_user with db feedback question_user 
      if feedback.question_user then
      	return false if question_user.nil?
      	return false if question_user.id.to_s != feedback.question_user.id.to_s
      end
      
      return Feedback.where(_id: feedback.id).delete
  	end
  	
  	#*description*: reply feedback
    #
    #*params*:
    #* feedback_type: type for feedback
    #* answer_user: user who reply the feedback_id's feedback
    #* message_content: message content
    #
    #*retval*:
    #* false or true
  	def reply(feedback_id, answer_user, message_content)
  	
  		# answer_user must be admin
  		return false if answer_user.nil? || ( answer_user && !answer_user.is_admin)
  		
  		#find feedback
  		feedback = Feedback.find(feedback_id)
      return false if feedback.nil?
      
      # if feedback 's question_user is nil, do not need reply.
      return false if feedback.question_user.nil?
      
      title = "反馈意见回复:"+ feedback.title
      # 1 in the message type 
      message = Message.create_new(title, 
      		message_content, 
      		answer_user.id.to_s,
      		1,
      		feedback.question_user.id.to_s)
      		
      stat = message.save 
      
      if stat then
      	feedback.is_answer = true
      	feedback.save 
      end
      
      return stat 
      
  	end
  	
  	#*description*: list feedback with one condition
  	#
  	#*retval*:
    #feedback array
    def condition(key, value)
      return nil if %{type title is_answer}.split.delete(key.to_s).nil?
    	return Feedback.where(feedback_type: value).desc(:updated_at) if key.to_s == "type"
      return Feedback.where(title: /.*#{value}.*/).desc(:updated_at) if key.to_s == "title"
      return Feedback.where(is_answer: value).desc(:updated_at) if key.to_s == "is_answer"
    end
  	
  end 
  
end

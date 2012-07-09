# coding: utf-8

class Feedback
	include Mongoid::Document
	include Mongoid::Timestamps
	
	field :feedback_type, :type => Integer
	field :title, :type => String
	field :content, :type => String
	field :is_answer, :type => Boolean, :default => false
	
	attr_accessible :feedback_type, :title, :content
	
	belongs_to :question_user, class_name: "User", inverse_of: :question_feedback
	belongs_to :answer_user, class_name: "User", inverse_of: :answer_feedback
	
	# the max of multiple type value => 2**7
	MAX_TYPE = 7
	
	scope :answered, where(is_answer: true).desc(:udpated_at)
	scope :unanswer, where(is_answer: false).desc(:updated_at)
	
	#--
	# instance methods
	#++
	
	def is_answer?
		self.is_answer
	end
	
	#*description*: verify the feedback_type value
	#
	#*params*:
	#* type_number: the number of type: 1, 2, 4, ...
	#
	#*retval*:
	#no return
	def feedback_type=(type_number)
	
		type_number_class = type_number.class
	
		type_number = type_number.to_i
		
		# if type_number is string, to_i will return 0.
		# "0" will raise RangeError, "type1" will raise TypeError
		raise TypeError if type_number_class != Fixnum && type_number == 0
		
		if (type_number % 2 != 0 && type_number !=1) || 
			type_number <= 0 || type_number > 2**MAX_TYPE
			
			raise RangeError
		end
		super
	end

	
	#--
	# class methods
	#++
	
	class << self
	
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
				[feedback.question_user.id.to_s])

			stat = message.save

			if stat then
				feedback.is_answer = true
				feedback.save
			end

			return stat
		
		end
		
		#*description*: list feedback s with condition
		#
		#*retval*:
		#feedback array 
		def find_by_type(type_number=0, value)
			return [] if !type_number.instance_of?(Fixnum)
			feedbacks = []
			
			# if type_number = 0
			if type_number == 0 then
				feedbacks = Feedback.where(title: /.*#{value}.*/) + Feedback.where(content: /.*#{value}.*/)
				feedbacks.uniq!{|f| f._id.to_s }
				feedbacks.sort!{|v1, v2| v2.updated_at <=> v1.updated_at}
				
			else
				# if type_number != 0
				MAX_TYPE.downto(0).each { |element| 
					feedbacks_tmp = []
					if type_number / (2**element) == 1 then
						feedbacks_tmp = Feedback.where(title: /.*#{value}.*/, feedback_type: 2**element) + Feedback.where(content: /.*#{value}.*/, feedback_type: 2**element)
						feedbacks_tmp.uniq!{|f| f._id.to_s }
					end
					type_number = type_number % 2**element
					feedbacks = feedbacks + feedbacks_tmp
				}
			
				feedbacks.sort!{|v1, v2| v2.updated_at <=> v1.updated_at} if feedbacks.count > 1
			end
			
			return feedbacks	
		end
		
	end 
	
end

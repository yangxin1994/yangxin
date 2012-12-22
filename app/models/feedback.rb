# coding: utf-8

class Feedback
	include Mongoid::Document
	include Mongoid::Timestamps
	
	field :feedback_type, :type => Integer
	field :title, :type => String
	field :content, :type => String
	field :is_answer, :type => Boolean, :default => false
	# add attr to store reply message
	field :reply_message, :type => String
	
	attr_accessible :feedback_type, :title, :content

	validates_presence_of :feedback_type, :title, :content
	
	belongs_to :question_user, class_name: "User", inverse_of: :question_feedback
	belongs_to :answer_user, class_name: "User", inverse_of: :answer_feedback

	scope :answered, where(is_answer: true)
	scope :unanswer, where(is_answer: false)
	
	# the max of multiple type value => 2**7
	MAX_TYPE = 7
	
	#--
	# instance methods
	#++

	
	#--
	# class methods
	#++
	
	class << self

		#*description*: verify the feedback_type value
		#
		#*params*:
		#* type_number: the number of type: 1, 2, 4, ...
		#
		#*retval*:
		#no return
		def verify_feedback_type(type_number)
		
			type_number_class = type_number.class
			temp = type_number
			type_number = type_number.to_i
			
			# if type_number is string, to_i will return 0.
			# "0" will return RangeError, "type1" will return TypeError
			return ErrorEnum::FEEDBACK_TYPE_ERROR if type_number_class != Fixnum && type_number == 0 && temp.to_s.strip !="0"
			
			if (type_number % 2 != 0 && type_number !=1) || 
				type_number <= 0 || type_number > 2**MAX_TYPE
				
				return ErrorEnum::FEEDBACK_RANGE_ERROR
			end
			return true
		end

		# CURD

		#*description*:
		# different with find method, find_by_id will return ErrorEnum if not found.
		#
		#*params*:
		#* feedback_id
		#
		#*retval*:
		#* ErrorEnum or feedback instance
		def find_by_id(feedback_id)
			feedback = Feedback.where(_id: feedback_id.to_s).first
			return ErrorEnum::FEEDBACK_NOT_EXIST if feedback.nil?
			return feedback
		end

		#*description*:
		# create feedback for different type.
		#
		#*params*:
		#* new_feedback: a hash for feedback attributes.
		#* user: who create feedback
		#
		#*retval*:
		#* ErrorEnum or feedback instance
		def create_feedback(new_feedback, user=nil)
			new_feedback[:feedback_type] = new_feedback[:feedback_type] || 1
			retval = verify_feedback_type(new_feedback[:feedback_type])
			return retval if retval != true

			feedback = Feedback.new(new_feedback)
			feedback.question_user = user if user && user.instance_of?(User)

			if feedback.save then
				return feedback 
			else
				return ErrorEnum::FEEDBACK_SAVE_FAILED
			end
		end

		#*description*:
		# update feedback 
		#
		#*params*:
		#* feedback_id
		#* attributes: update attributes
		#* user: who update feedback
		#
		#*retval*:
		#* ErrorEnum or feedback instance
		def update_feedback(feedback_id, attributes, user=nil)
			feedback = Feedback.find_by_id(feedback_id)
			return feedback if !feedback.instance_of?(Feedback)

			if attributes[:feedback_type] then
				retval = verify_feedback_type(attributes[:feedback_type]) 
				return retval if retval != true
			end

			if !feedback.question_user.nil? then
				return ErrorEnum::FEEDBACK_NOT_CREATOR if user.nil? || user != feedback.question_user
				return ErrorEnum::FEEDBACK_CANNOT_UPDATE if feedback.is_answer == true
			else
				return ErrorEnum::FEEDBACK_CANNOT_UPDATE
			end

			if feedback.update_attributes(attributes) then
				return feedback 
			else
				return ErrorEnum::FEEDBACK_SAVE_FAILED
			end
		end

		#*description*:
		# destroy feedback 
		#
		#*params*:
		#* feedback_id
		#* user: must be creator or admin
		#
		#*retval*:
		#* ErrorEnum or Boolean
		def destroy_by_id(feedback_id, user)
			feedback = Feedback.find_by_id(feedback_id)
			return feedback if !feedback.instance_of?(Feedback)

			if !feedback.question_user.nil? then
				return ErrorEnum::FEEDBACK_NOT_CREATOR if user.nil? || (user != feedback.question_user && !user.is_admin)
			else
				return ErrorEnum::FEEDBACK_CANNOT_DELETE if user.nil? || !user.is_admin
			end

			return feedback.destroy
		end

		#*description*: list feedbacks with condition
		#
		#*retval*:
		#feedback array 
		def list_by_type_and_value(type_number, value, user=nil)

			#if value is empty, involve list_by_type
			list_by_type(type_number) if value.nil? || (value && value.to_s.strip == "")

			#verify params
			return ErrorEnum::FEEDBACK_TYPE_ERROR if type_number && type_number.to_i ==0 && type_number.to_s.strip != "0"
			return ErrorEnum::FEEDBACK_RANGE_ERROR if type_number && (type_number.to_i < 0 || type_number.to_i >= 2**(MAX_TYPE+1))

			type_number = type_number.to_i

			return [] if !type_number.instance_of?(Fixnum) || type_number <= 0
			feedbacks = []

			value = value.to_s.gsub(/[*]/, ' ')
			
			# if type_number != 0
			MAX_TYPE.downto(0).each { |element| 
				feedbacks_tmp = []
				if type_number / (2**element) == 1 then
					if user.nil? then					
						feedbacks_tmp = Feedback.where(title: /.*#{value}.*/, feedback_type: 2**element) + Feedback.where(content: /.*#{value}.*/, feedback_type: 2**element)
					else
						feedbacks_tmp = Feedback.where(question_user_id: user.id, title: /.*#{value}.*/, feedback_type: 2**element) + Feedback.where(question_user_id: user.id, content: /.*#{value}.*/, feedback_type: 2**element)
					end
					feedbacks_tmp.uniq!{|f| f._id.to_s }
				end
				type_number = type_number % 2**element
				feedbacks = feedbacks + feedbacks_tmp
			}
		
			feedbacks.sort!{|v1, v2| v2.updated_at <=> v1.updated_at} if feedbacks.count > 1
			
			return feedbacks	
		end

		#*description*: list feedbacks with types
		#
		#*params*
		#* type_number: the search types number which is be 1, 2, 3, 7. 3=1+2; 7=1+2+4.
		#
		#*retval*:
		#feedback array
		def list_by_type(type_number, user=nil)
			#verify params
			return ErrorEnum::FEEDBACK_TYPE_ERROR if type_number && type_number.to_i ==0 && type_number.to_s.strip != "0"
			return ErrorEnum::FEEDBACK_RANGE_ERROR if type_number && (type_number.to_i < 0 || type_number.to_i >= 2**(MAX_TYPE+1))

			type_number = type_number.to_i
			
			return [] if !type_number.instance_of?(Fixnum) || type_number <= 0
			feedbacks = []

			MAX_TYPE.downto(0).each { |element| 
				feedbacks_tmp=[]
				if type_number / (2**element) == 1 then
					feedbacks_tmp = Feedback.where(feedback_type: 2**element) if user.nil?
					feedbacks_tmp = Feedback.where(question_user_id: user.id,feedback_type: 2**element) if !user.nil?
				end
				type_number = type_number % 2**element
				feedbacks = feedbacks + feedbacks_tmp
			}
			feedbacks.sort!{|v1, v2| v2.updated_at <=> v1.updated_at} if feedbacks.count > 1
			return feedbacks
		end

		#*description*:
		#
		#*params*
		#* type_number: the search types number which is be 1, 2, 3, 7. 3=1+2; 7=1+2+4.
		#* is_answer: true or false
		#
		#*retval*:
		# a feedback array
		def list_by_type_and_answer(type_number, is_answer, user=nil)

			feedbacks = list_by_type(type_number)

			return feedbacks if !feedbacks.instance_of?(Array)
			if feedbacks.count > 0 then
				feedbacks.select!{|o| o.is_answer == is_answer}
			end

			return feedbacks
		end


		#*description*: reply feedback
		#
		#*params*:
		#* feedback_type: type for feedback
		#* answer_user: user who reply the feedback_id's feedback
		#* message_content: message content
		#
		#*retval*:
		# it will return Message.create_new 's Return value;
		def reply(feedback_id, answer_user, message_content)

			# answer_user must be admin
			return ErrorEnum::REQUIRE_ADMIN if answer_user.nil? || ( answer_user && !answer_user.is_admin)

			#find feedback
			feedback = Feedback.find(feedback_id)
			return ErrorEnum::FEEDBACK_NOT_EXIST if feedback.nil?

			# if feedback 's question_user is nil, do not need reply.
			return ErrorEnum::FEEDBACK_NO_QUESTION_USER if feedback.question_user.nil?

			title = "反馈意见回复:"+ feedback.title.to_s
			# 1 in the message type
			retval = answer_user.create_message(
				title,
				message_content,
				[feedback.question_user.id.to_s])

			if retval.is_a? Message
				feedback.is_answer = true 
				feedback.reply_message = message_content
				feedback.save 
			end
					
			return retval

			# __return retval__ same as follows:
			#
			#case retval
			# when ErrorEnum::UNAUTHROZIED
			# 	return ErrorEnum::UNAUTHROZIED
			# when ErrorEnum::RECEIVER_CAN_NOT_BLANK
			# 	return ErrorEnum::RECEIVER_CAN_NOT_BLANK
			# when ErrorEnum::TITLE_CAN_NOT_BLANK
			# 	return ErrorEnum::TITLE_CAN_NOT_BLANK
			# when ErrorEnum::CONTENT_CAN_NOT_BLANK
			# 	return ErrorEnum::CONTENT_CAN_NOT_BLANK
			# when Message then
			# 	return retval
			# end
			# 
			# But, anymore. The Error which is from Message.create_new() should be no return.
			# Because, the params had been verified.
		end		
	end 
	
end

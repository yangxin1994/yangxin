class Faq
	include Mongoid::Document 
	include Mongoid::Timestamps

	# faq_type divide from 1, 2, 4, 8, ...,
	field :faq_type, :type => Integer
	field :question, :type => String
	field :answer, :type => String
					
	belongs_to :user

	attr_accessible :faq_type, :question, :answer

	validates_presence_of :faq_type, :question, :answer
		
	#faq_type max number
	MAX_TYPE = 7
	
	#--
	# class methods
	#++
	class << self	

		#*description*: verify the faq_type value
		#
		#*params*:
		#* type_number: the number of type: 1, 2, 4, ...
		#
		#*retval*:
		#true or ErrorEnum
		def verify_faq_type(type_number)
		
			type_number_class = type_number.class
			temp = type_number
			type_number = type_number.to_i
			
			# if type_number is string, to_i will return 0.
			# "0" will return RangeError, "type1" will return TypeError
			return ErrorEnum::FAQ_TYPE_ERROR if type_number_class != Fixnum && type_number == 0 && temp.to_s.strip !="0"
			
			if (type_number % 2 != 0 && type_number !=1) || 
				type_number <= 0 || type_number > 2**MAX_TYPE
				
				return ErrorEnum::FAQ_RANGE_ERROR
			end
			return true
		end

		# CURD

		#*description*:
		# different with find method, find_by_id will return ErrorEnum if not found.
		#
		#*params*:
		#* faq_id
		#
		#*retval*:
		#* ErrorEnum or faq instance
		def find_by_id(faq_id)
			faq = Faq.where(_id: faq_id.to_s).first
			return ErrorEnum::FAQ_NOT_EXIST if faq.nil?
			return faq
		end

		#*description*:
		# create faq for different type.
		#
		#*params*:
		#* new_faq: a hash for faq attributes.
		#* user: who create faq
		#
		#*retval*:
		#* ErrorEnum or faq instance
		def create_faq(new_faq, user)
			new_faq[:faq_type] = new_faq[:faq_type] || 1
			retval = verify_faq_type(new_faq[:faq_type])
			return retval if retval != true

			faq = Faq.new(new_faq)
			faq.user = user if user && user.instance_of?(User)

			if faq.save then
				return faq 
			else
				return ErrorEnum::FAQ_SAVE_FAILED
			end
		end

		#*description*:
		# update faq 
		#
		#*params*:
		#* faq_id
		#* attributes: update attributes
		#* user: who update faq
		#
		#*retval*:
		#* ErrorEnum or faq instance
		def update_faq(faq_id, attributes, user)
			faq = Faq.find_by_id(faq_id)
			return faq if !faq.instance_of?(Faq)

			if attributes[:faq_type] then
				retval = verify_faq_type(attributes[:faq_type]) 
				return retval if retval != true
			end

			faq.user = user if user && user.instance_of?(User)

			if faq.update_attributes(attributes) then
				return faq 
			else
				return ErrorEnum::FAQ_SAVE_FAILED
			end
		end

		#*description*:
		# destroy faq 
		#
		#*params*:
		#* faq_id
		#
		#*retval*:
		#* ErrorEnum or Boolean
		def destroy_by_id(faq_id)
			faq = Faq.find_by_id(faq_id)
			return faq if !faq.instance_of?(Faq)
			return faq.destroy
		end
		
		#*description*: list faqs with types and value
		#
		#*retval*:
		# faq array 
		def list_by_type_and_value(type_number=0, value)

			#if value is empty, involve list_by_type
			list_by_type(type_number) if value.nil? || (value && value.to_s.strip == "")

			#verify params
			return ErrorEnum::FAQ_TYPE_ERROR if type_number && type_number.to_i ==0 && type_number.to_s.strip != "0"
			return ErrorEnum::FAQ_RANGE_ERROR if type_number && (type_number.to_i < 0 || type_number.to_i >= 2**(MAX_TYPE+1))		

			type_number = type_number.to_i
			
			return [] if !type_number.instance_of?(Fixnum) || type_number <= 0
			faqs = []
			
			value = value.gsub(/[*]/, ' ')

			# if type_number legal
			MAX_TYPE.downto(0).each { |element| 
				faqs_tmp = []
				if type_number / (2**element) == 1 then
					faqs_tmp = Faq.where(question: /.*#{value}.*/, faq_type: 2**element) + Faq.where(answer: /.*#{value}.*/, faq_type: 2**element)
					faqs_tmp.uniq!{|f| f._id.to_s }
				end
				type_number = type_number % 2**element
				faqs = faqs + faqs_tmp
			}
			
			faqs.sort!{|v1, v2| v2.updated_at <=> v1.updated_at} if faqs.count > 1
			
			return faqs	
		end
		
		#*description*: list faqs with types
		#
		#*retval*:
		#faq array
		def list_by_type(type_number=0)
			#verify params
			return ErrorEnum::FAQ_TYPE_ERROR if type_number && type_number.to_i ==0 && type_number.to_s.strip != "0"
			return ErrorEnum::FAQ_RANGE_ERROR if type_number && (type_number.to_i < 0 || type_number.to_i >= 2**(MAX_TYPE+1))

			type_number = type_number.to_i
			
			return [] if !type_number.instance_of?(Fixnum) || type_number <= 0
			faqs = []

			MAX_TYPE.downto(0).each { |element| 
				faqs_tmp=[]
				if type_number / (2**element) == 1 then
					faqs_tmp = Faq.where(faq_type: 2**element)
				end
				type_number = type_number % 2**element
				faqs = faqs + faqs_tmp
			}
			faqs.sort!{|v1, v2| v2.updated_at <=> v1.updated_at} if faqs.count > 1
			return faqs
		end
	end
end

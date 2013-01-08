class PublicNotice
	include Mongoid::Document
	include Mongoid::Timestamps

	field :title, :type => String
	field :content, :type => String
	field :attachment, :type => String
	field :public_notice_type, :type => Integer

	belongs_to :user
	
	attr_accessible :title, :content, :attachment, :public_notice_type

	validates_presence_of :title, :public_notice_type
	
	# the max of multiple type value => 2**7
	MAX_TYPE = 7
	
	#--
	# instance methods
	#++
	#
	
	
	#--
	# class methods
	#++
	
	class << self

		#*description*: verify the public_notice_type value
		#
		#*params*:
		#* type_number: the number of type: 1, 2, 4, ...
		#
		#*retval*:
		#no return
		def verify_public_notice_type(type_number)
		
			type_number_class = type_number.class
			temp = type_number
			type_number = type_number.to_i
			
			# if type_number is string, to_i will return 0.
			# "0" will return RangeError, "type1" will return TypeError
			return ErrorEnum::PUBLIC_NOTICE_TYPE_ERROR if type_number_class != Fixnum && type_number == 0 && temp.to_s.strip !="0"
			
			if (type_number % 2 != 0 && type_number !=1) || 
				type_number <= 0 || type_number > 2**MAX_TYPE
				
				return ErrorEnum::PUBLIC_NOTICE_RANGE_ERROR
			end
			return true
		end

		# CURD

		#*description*:
		# different with find method, find_by_id will return ErrorEnum if not found.
		#
		#*params*:
		#* public_notice_id
		#
		#*retval*:
		#* ErrorEnum or public_notice instance
		def find_by_id(public_notice_id)
			public_notice = PublicNotice.where(_id: public_notice_id.to_s).first
			return ErrorEnum::PUBLIC_NOTICE_NOT_EXIST if public_notice.nil?
			return public_notice
		end

		#*description*:
		# create public_notice for different type.
		#
		#*params*:
		#* new_public_notice: a hash for public_notice attributes.
		#* user: who create public_notice
		#
		#*retval*:
		#* ErrorEnum or public_notice instance
		def create_public_notice(new_public_notice, user)
			new_public_notice[:public_notice_type] = new_public_notice[:public_notice_type] || 1
			retval = verify_public_notice_type(new_public_notice[:public_notice_type])
			return retval if retval != true

			public_notice = PublicNotice.new(new_public_notice)
			public_notice.user = user if user && user.instance_of?(User)

			if public_notice.save then
				return public_notice 
			else
				return ErrorEnum::PUBLIC_NOTICE_SAVE_FAILED
			end
		end

		#*description*:
		# update public_notice 
		#
		#*params*:
		#* public_notice_id
		#* attributes: update attributes
		#* user: who update public_notice
		#
		#*retval*:
		#* ErrorEnum or public_notice instance
		def update_public_notice(public_notice_id, attributes, user)
			public_notice = PublicNotice.find_by_id(public_notice_id)
			return public_notice if !public_notice.instance_of?(PublicNotice)

			if attributes[:public_notice_type] then
				retval = verify_public_notice_type(attributes[:public_notice_type]) 
				return retval if retval != true
			end

			public_notice.user = user if user && user.instance_of?(User)

			if public_notice.update_attributes(attributes) then
				return public_notice 
			else
				return ErrorEnum::PUBLIC_NOTICE_SAVE_FAILED
			end
		end

		#*description*:
		# destroy public_notice 
		#
		#*params*:
		#* public_notice_id
		#
		#*retval*:
		#* ErrorEnum or Boolean
		def destroy_by_id(public_notice_id)
			public_notice = PublicNotice.find_by_id(public_notice_id)
			return public_notice if !public_notice.instance_of?(PublicNotice)
			return public_notice.destroy
		end

		#*description*: list public_notice s with condition
		#
		#*retval*:
		#public_notice array 
		def list_by_type_and_value(type_number=0, value)

			#if value is empty, involve list_by_type
			list_by_type(type_number) if value.nil? || (value && value.to_s.strip == "")

			#verify params
			return ErrorEnum::PUBLIC_NOTICE_TYPE_ERROR if type_number && type_number.to_i ==0 && type_number.to_s.strip != "0"
			return ErrorEnum::PUBLIC_NOTICE_RANGE_ERROR if type_number && (type_number.to_i < 0 || type_number.to_i >= 2**(MAX_TYPE+1))	

			type_number = type_number.to_i

			return [] if !type_number.instance_of?(Fixnum) || type_number <= 0
			public_notices = []
			
			value = value.to_s.gsub(/[*]/, ' ')

			# if type_number != 0
			MAX_TYPE.downto(0).each { |element| 
				public_notices_tmp = []
				if type_number / (2**element) == 1 then
					public_notices_tmp = PublicNotice.where(title: /.*#{value}.*/, public_notice_type: 2**element) + PublicNotice.where(content: /.*#{value}.*/, public_notice_type: 2**element)
					public_notices_tmp.uniq!{|f| f._id.to_s }
				end
				type_number = type_number % 2**element
				public_notices = public_notices + public_notices_tmp
			}
		
			public_notices.sort!{|v1, v2| v2.updated_at <=> v1.updated_at} if public_notices.count > 1
			
			return public_notices	
		end

		#*description*: list public notices with types
		#
		#*retval*:
		#public_notice array
		def list_by_type(type_number=0)
			#verify params
			return ErrorEnum::PUBLIC_NOTICE_TYPE_ERROR if type_number && type_number.to_i ==0 && type_number.to_s.strip != "0"
			return ErrorEnum::PUBLIC_NOTICE_RANGE_ERROR if type_number && (type_number.to_i < 0 || type_number.to_i >= 2**(MAX_TYPE+1))

			type_number = type_number.to_i
			
			return [] if !type_number.instance_of?(Fixnum) || type_number <= 0
			public_notices = []

			MAX_TYPE.downto(0).each { |element| 
				public_notices_tmp=[]
				if type_number / (2**element) == 1 then
					public_notices_tmp = PublicNotice.where(public_notice_type: 2**element)
				end
				type_number = type_number % 2**element
				public_notices = public_notices + public_notices_tmp
			}
			public_notices.sort!{|v1, v2| v2.updated_at <=> v1.updated_at} if public_notices.count > 1
			return public_notices
		end
		
	end 
end
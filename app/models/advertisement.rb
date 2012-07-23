class Advertisement
	include Mongoid::Document
	include Mongoid::Timestamps
	
	field :title, :type => String
	field :linked, :type => String
	field :image_location, :type => String
	field :activate, :type => Boolean, :default => false
	
	belongs_to :user
	
	attr_accessible :title, :linked, :image_location, :activate

	validates_presence_of :title, :linked, :image_location
	validates_uniqueness_of :title
	
	#--
	# scope is same with class methods
	#++
	scope :unactivate, where(activate: false)
	scope :activated, where(activate: true)
	scope :list_by_title, ->(title){ where(title: title.to_s.strip) }
	
	#--
	# instance methods
	#++
	
	#--
	# class methods
	#++

	class << self

		# CURD

		#*description*:
		# different with find method, find_by_id will return ErrorEnum if not found.
		#
		#*params*:
		#* advertisement_id
		#
		#*retval*:
		#* ErrorEnum or advertisement instance
		def find_by_id(advertisement_id)
			advertisement = Advertisement.where(_id: advertisement_id.to_s).first
			return ErrorEnum::ADVERTISEMENT_NOT_EXIST if advertisement.nil?
			return advertisement
		end

		#*description*:
		# create advertisement for different type.
		#
		#*params*:
		#* new_advertisement: a hash for advertisement attributes.
		#* user: who create advertisement
		#
		#*retval*:
		#* ErrorEnum or advertisement instance
		def create_advertisement(new_advertisement, user)
			advertisement = Advertisement.new(new_advertisement)

			advertisement.user = user if user && user.instance_of?(User)

			if advertisement.save then
				return advertisement 
			else
				return ErrorEnum::ADVERTISEMENT_SAVE_FAILED
			end
		end

		#*description*:
		# update advertisement 
		#
		#*params*:
		#* advertisement_id
		#* attributes: update attributes
		#* user: who update advertisement
		#
		#*retval*:
		#* ErrorEnum or advertisement instance
		def update_advertisement(advertisement_id, attributes, user)
			advertisement = Advertisement.find_by_id(advertisement_id)
			return advertisement if !advertisement.instance_of?(Advertisement)

			advertisement.user = user if user && user.instance_of?(User)

			if advertisement.update_attributes(attributes) then
				return advertisement 
			else
				return ErrorEnum::ADVERTISEMENT_SAVE_FAILED
			end
		end

		#*description*:
		# destroy advertisement 
		#
		#*params*:
		#* advertisement_id
		#
		#*retval*:
		#* ErrorEnum or Boolean
		def destroy_by_id(advertisement_id)
			advertisement = Advertisement.find_by_id(advertisement_id)
			return advertisement if !advertisement.instance_of?(Advertisement)
			return advertisement.destroy
		end

	end
	
end

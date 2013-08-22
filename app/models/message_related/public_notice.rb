class PublicNotice
	include Mongoid::Document
	include Mongoid::Timestamps

	field :title, :type => String
	field :content, :type => String
	field :attachment, :type => String
	## status can be 1(close)，2(publish) 4(deleted, just can be change by destroy method)
	field :status, :type => Integer, :default => 2

	belongs_to :user

	# index({ title: 1, public_notice_type: 1 }, { background: true } )
	# index({ public_notice_type: 1, content: 1 }, { background: true } )
	
	# attr_accessible :title, :content, :attachment, :status#, :public_notice_type

	scope :opend, where(:status => 2)
	scope :closed, where(:status => 1)

	validates_presence_of :title#, :public_notice_type
		
	class << self

		def find_by_id(public_notice_id)
			public_notice = PublicNotice.where(_id: public_notice_id.to_s).first
			return public_notice
		end

		def find_valid_notice
			PublicNotice.in(status: [1, 2]).desc(:updated_at)
		end

		def find_by_title(title)
			title.blank? ? self : self.where(:title => /.*#{title}.*/)
		end

		def create_public_notice(new_public_notice, user)
			public_notice = PublicNotice.new(new_public_notice)
			user.public_notices << public_notice if user && user.instance_of?(User)
			return public_notice.save			
		end

		def update_public_notice(public_notice_id, attributes, user)
			public_notice = PublicNotice.find_by_id(public_notice_id)
			return PUBLIC_NOTICE_NOT_EXIST if public_notice.blank?
			return ErrorEnum::PUBLIC_NOTICE_STATUS_ERROR if ![1, 2].include?(attributes[:status])

			public_notice.user = user if user && user.instance_of?(User)
			return public_notice.update_attributes(attributes)
		end

		def destroy_by_id(public_notice_id)
			public_notice = PublicNotice.find_by_id(public_notice_id)
			return ErrorEnum::PUBLIC_NOTICE_NOT_EXIST if public_notice.blank?
			return public_notice.update_attribute("status", 4)
		end
	end 
end
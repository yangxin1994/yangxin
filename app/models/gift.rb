require 'tool'
require 'error_enum'
class Gift
	include Mongoid::Document
	include Mongoid::Timestamps

	OFF_THE_SHELF = 2
	ON_THE_SHELF = 1
	DELETED = 4

	VIRTUAL = 1
	REAL = 2
	MOBILE_CHARGE = 4
	ALIPAY = 8
	JIFENBAO = 16
	QQ_COIN = 32

	SINGLE = 1
	INTERVAL = 2
	ARRAY = 4

	DEFAULT_IMG = '/assets/od-quillme/gifts/default.png'

	# 2 off the shelf, 1 on the shelf, 4 deleted
	field :status, :type => Integer, default: 2
	# 1 for virtual gift, 2 for real goods gift, 4 for mobile change, 8 for alypay transfer, 16 for jifenbao, 32 for qq coin
	field :type, :type => Integer, default: 0
	field :title, :type => String, default: ""
	field :description, :type => String, default: ""
	field :quantity, :type => Integer, default: 0
	field :point, :type => Integer, default: 0
	field :exchange_count, :type => Integer, default: 0
	field :price, :type => Float, default: 0.0
	field :redeem_number, :type => Hash, default: {"mode" => SINGLE}

	has_one :photo, :class_name => "Material", :inverse_of => 'gift'
	has_many :orders

	#default_scope order_by(:created_at.desc)
	scope :normal, where(:status.in => [OFF_THE_SHELF, ON_THE_SHELF])
	scope :on_shelf, where(:status => ON_THE_SHELF)
	scope :real, where(:type => REAL)
	index({ type: 1, status: 1 }, { background: true } )

	def self.find_by_id(gift_id)
		return self.normal.where(:_id => gift_id).first
	end

	def self.find_real_gift(desc_type)
		gifts = self.on_shelf.real.desc("#{desc_type}")
		gifts = gifts.map do |gift| 
			gift['photo_src'] = gift.photo.nil? ? Gift::DEFAULT_IMG : gift.photo.picture_url
			gift
		end
		return gifts
	end

	def self.create_gift(gift)
		photo_url = gift.delete("photo_url")
		material = Material.create_image(photo_url)
		gift = Gift.new(gift)
		gift.price = gift.point / 100 if gift.price.blank?
		gift.save
		gift.photo = material
		gift["photo_url"] = material.value
		return gift
	end

	def self.generate_opt(order,gift)
		opt = {}
		real_gift = self.find_by_id(gift)

		if real_gift.present?
			opt["receiver"]    = order[:receiver]	
			opt["mobile"]      = order[:mobile]
			opt["address"]     = order[:address]
			opt["street_info"] = order[:street_info]
			opt["postcode"]    = order[:postcode]			
		else
			opt['mobile'] = order[:account] if gift == 'phone_num'
			opt['alipay_account'] = order[:account] if gift == 'ali_num'
			opt['alipay_account'] = order[:account] if gift == 'jifen_num'
			opt['qq'] = order[:account] if gift == 'qq_num'			
		end

		return opt
	end

	def update_gift(gift)
		photo_url = gift.delete("photo_url")
		if !photo_url.blank? && photo_url != self.photo.picture_url
			material = Material.create_image(photo_url)
			self.photo = material
		end
		return self.update_attributes(gift)
	end

	def self.search_gift(title, status, type)
		gifts = Gift.normal
		gifts = gifts.where(:title => /#{title}/) if !title.blank?
		gifts = gifts.where(:status.in => Tool.convert_int_to_base_arr(status)) if !status.blank? && status != 0
		gifts = gifts.where(:type.in => Tool.convert_int_to_base_arr(type)) if !type.blank? && type != 0
		gifts.each do |g|
			g["photo_url"] = g.photo.try(:value)
		end
		return gifts
	end

	def delete_gift
		self.status = DELETED
		return self.save
	end

	def self.check_params(gift)
		material_id = gift["material_id"]
		material = Material.find_by_id(material_id)
		return ErrorEnum::MATERIAL_NOT_EXIST if material.nil?
		return Errorenum::WRONG_GIFT_TYPE if ![1,2,4].include?(gift["type"].to_i)
		return true
	end


	def self.generate_gift_id(order_type)
		gift = self.find_by_id(order_type)
		if gift.present?
			return gift._id
		else
			case order_type.to_s
			when 'phone_num'
				return self.where(:type => MOBILE_CHARGE).on_shelf.first.try(:_id) 
			when 'jifen_num'
				return self.where(:type => JIFENBAO).on_shelf.first.try(:_id)
			when 'ali_num'
				return self.where(:type => ALIPAY).on_shelf.first.try(:_id)
			when 'qq_num'
				return self.where(:type => QQ_COIN).on_shelf.first.try(:_id)
			else
				return false
			end
		end
	end


    #订单(兑换)流程走完之后该值加一，表示该礼品兑换的次数
	def inc_exchange_count
      inc(:exchange_count, 1)
	end
end

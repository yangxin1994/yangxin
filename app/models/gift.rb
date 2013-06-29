# encoding: utf-8
require 'tool'
class Gift
	include Mongoid::Document
	include Mongoid::Timestamps

	OFF_THE_SHELF = 1
	ON_THE_SHELF = 2
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


	# 1 off the shelf, 2 on the shelf, 4 deleted
	field :status, :type => Integer, default: 1
	# 1 for virtual gift, 2 for virtual gift whose number can be selected, 4 for real gift
	field :type, :type => Integer, default: 1
	field :title, :type => String, default: ""
	field :description, :type => String, default: ""
	field :quantity, :type => Integer, default: 0
	field :point, :type => Integer, default: 0
    field :exchange_count, :type => Integer, default: 0
    field :redeem_number, :type => Hash, default: {"mode" => SINGLE}

	has_one :photo, :class_name => "Material", :inverse_of => 'gift'

	default_scope order_by(:created_at.desc)

	scope :normal, where(:status.in => [OFF_THE_SHELF, ON_THE_SHELF])

	index({ type: 1, status: 1 }, { background: true } )

	def self.find_by_id(gift_id)
		return self.normal.where(:_id => gift_id).first
	end

	def self.create_gift(gift)
		photo_url = gift.delete("photo_url")
		material = Material.create_image(photo_url)
		gift = Gift.new(gift)
		gift.save
		gift.photo = material
		gift["photo_url"] = material.value
		return gift
	end

	def update_gift(gift)
		photo_url = gift.delete("photo_url")
		if !photo_url.blank? && photo_url != self.photo.value
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

    #订单(兑换)流程走完之后该值加一，表示该礼品兑换的次数
	def inc_exchange_count
      inc(:exchange_count, 1)
	end
end
